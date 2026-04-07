import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/ride_model.dart';
import 'package:nabour_app/utils/logger.dart';

/// Service for managing offline capabilities and data synchronization
class OfflineService {
  static const String _offlineQueueKey = 'offline_queue';
  static const String _offlineDataKey = 'offline_data';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const int _maxOfflineItems = 100;


  late SharedPreferences _prefs;
  final Connectivity _connectivity = Connectivity();
  bool _isInitialized = false;
  bool _isOnline = true;
  final List<OfflineOperation> _offlineQueue = [];
  final Map<String, dynamic> _offlineData = {};

  /// Initialize the offline service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    
    // Load offline queue and data
    await _loadOfflineQueue();
    await _loadOfflineData();
    
    // Monitor connectivity
    _monitorConnectivity();
    
    _isInitialized = true;
  }

  /// Check if the device is currently online
  bool get isOnline => _isOnline;

  /// Get the current offline queue size
  int get queueSize => _offlineQueue.length;

  /// Get the last sync timestamp
  DateTime? get lastSync {
    final timestamp = _prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Add an operation to the offline queue
  Future<void> addToOfflineQueue(OfflineOperation operation) async {
    if (!_isInitialized) await initialize();

    // Create operation with timestamp if not present
    final op = operation.timestamp == null 
        ? OfflineOperation(
            id: operation.id,
            type: operation.type,
            data: operation.data,
            timestamp: DateTime.now(),
            retryCount: operation.retryCount,
            maxRetries: operation.maxRetries,
          )
        : operation;

    _offlineQueue.add(op);
    
    // Limit queue size
    if (_offlineQueue.length > _maxOfflineItems) {
      _offlineQueue.removeAt(0);
    }

    await _saveOfflineQueue();
  }

  /// Store data offline
  Future<void> storeOfflineData(String key, dynamic data) async {
    if (!_isInitialized) await initialize();

    _offlineData[key] = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': 1,
    };

    await _saveOfflineData();
  }

  /// Retrieve offline data
  dynamic getOfflineData(String key) {
    if (!_isInitialized) return null;

    final entry = _offlineData[key];
    if (entry != null) {
      return entry['data'];
    }
    return null;
  }

  /// Check if offline data exists and is fresh
  bool hasFreshOfflineData(String key, {Duration maxAge = const Duration(hours: 24)}) {
    if (!_isInitialized) return false;

    final entry = _offlineData[key];
    if (entry != null) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
      final age = DateTime.now().difference(timestamp);
      return age <= maxAge;
    }
    return false;
  }

  /// Process offline queue when back online
  Future<void> processOfflineQueue() async {
    if (!_isOnline || _offlineQueue.isEmpty) return;

    final operations = List<OfflineOperation>.from(_offlineQueue);
    final failedOperations = <OfflineOperation>[];

    for (final operation in operations) {
      try {
        final success = await _executeOperation(operation);
        if (success) {
          _offlineQueue.remove(operation);
        } else {
          failedOperations.add(operation);
        }
      } catch (e) {
        failedOperations.add(operation);
        Logger.error('Failed to execute offline operation: $e', error: e);
      }
    }

    // Keep failed operations for retry
    _offlineQueue.clear();
    _offlineQueue.addAll(failedOperations);

    await _saveOfflineQueue();
    await _updateLastSync();
  }

  /// Clear expired offline data
  Future<void> cleanupExpiredData({Duration maxAge = const Duration(days: 7)}) async {
    if (!_isInitialized) return;

    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _offlineData.entries) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(entry.value['timestamp']);
      final age = now.difference(timestamp);
      
      if (age > maxAge) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _offlineData.remove(key);
    }

    await _saveOfflineData();
  }

  /// Get offline statistics
  Map<String, dynamic> getOfflineStats() {
    if (!_isInitialized) return {};

    return {
      'queueSize': _offlineQueue.length,
      'dataKeys': _offlineData.keys.length,
      'lastSync': lastSync?.toIso8601String(),
      'isOnline': _isOnline,
      'totalStorageSize': _calculateStorageSize(),
    };
  }

  /// Monitor network connectivity
  void _monitorConnectivity() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isConnected = results.isNotEmpty && results.first != ConnectivityResult.none;
      _isOnline = isConnected;
      
      if (_isOnline && _offlineQueue.isNotEmpty) {
        // Attempt to sync offline operations when back online
        _syncOfflineOperations();
      }
      
      Logger.debug('Connectivity changed: ${results.map((r) => r.name).join(', ')} - Online: $_isOnline');
    });
  }
  
  /// Sync offline operations when back online
  Future<void> _syncOfflineOperations() async {
    if (!_isOnline || _offlineQueue.isEmpty) return;
    
    Logger.debug('Syncing ${_offlineQueue.length} offline operations...');
    
    final operationsToRemove = <OfflineOperation>[];
    
    for (final operation in _offlineQueue) {
      try {
        final success = await _executeOperation(operation);
        if (success) {
          operationsToRemove.add(operation);
        } else if (operation.retryCount < operation.maxRetries) {
          operation.retryCount++;
        } else {
          // Max retries reached, remove from queue
          operationsToRemove.add(operation);
        }
      } catch (e) {
        Logger.error('Failed to sync operation ${operation.id}: $e', error: e);
        if (operation.retryCount < operation.maxRetries) {
          operation.retryCount++;
        } else {
          operationsToRemove.add(operation);
        }
      }
    }
    
    // Remove processed operations
    for (final operation in operationsToRemove) {
      _offlineQueue.remove(operation);
    }
    
    await _saveOfflineQueue();
    await _updateLastSync();
    
    Logger.info('Sync completed. ${operationsToRemove.length} operations processed.');
  }

  /// Load offline queue from storage
  Future<void> _loadOfflineQueue() async {
    final queueJson = _prefs.getString(_offlineQueueKey);
    if (queueJson != null) {
      try {
        final List<dynamic> queueList = jsonDecode(queueJson);
        _offlineQueue.clear();
        for (final item in queueList) {
          _offlineQueue.add(OfflineOperation.fromJson(item));
        }
      } catch (e) {
        Logger.error('Failed to load offline queue: $e', error: e);
        _offlineQueue.clear();
      }
    }
  }

  /// Save offline queue to storage
  Future<void> _saveOfflineQueue() async {
    try {
      final queueJson = jsonEncode(_offlineQueue.map((op) => op.toJson()).toList());
      await _prefs.setString(_offlineQueueKey, queueJson);
    } catch (e) {
      Logger.error('Failed to save offline queue: $e', error: e);
    }
  }

  /// Load offline data from storage
  Future<void> _loadOfflineData() async {
    final dataJson = _prefs.getString(_offlineDataKey);
    if (dataJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(dataJson);
        _offlineData.clear();
        _offlineData.addAll(data);
      } catch (e) {
        Logger.error('Failed to load offline data: $e', error: e);
        _offlineData.clear();
      }
    }
  }

  /// Save offline data to storage
  Future<void> _saveOfflineData() async {
    try {
      final dataJson = jsonEncode(_offlineData);
      await _prefs.setString(_offlineDataKey, dataJson);
    } catch (e) {
      Logger.error('Failed to save offline data: $e', error: e);
    }
  }

  /// Execute an offline operation
  Future<bool> _executeOperation(OfflineOperation operation) async {
    try {
      switch (operation.type) {
        case OfflineOperationType.createRide:
          return await _executeCreateRide(operation);
        case OfflineOperationType.updateRide:
          return await _executeUpdateRide(operation);
        case OfflineOperationType.deleteRide:
          return await _executeDeleteRide(operation);
        case OfflineOperationType.createUser:
          return await _executeCreateUser(operation);
        case OfflineOperationType.updateUser:
          return await _executeUpdateUser(operation);
        default:
          Logger.debug('Unknown operation type: ${operation.type}');
          return false;
      }
    } catch (e) {
              Logger.error('Failed to execute operation: $e', error: e);
      return false;
    }
  }

  /// Execute create ride operation
  Future<bool> _executeCreateRide(OfflineOperation operation) async {
    try {
      final rideData = operation.data;
      final ride = Ride(
        id: rideData['id'] ?? '',
        passengerId: rideData['passengerId'] ?? '',
        driverId: rideData['driverId'],
        startAddress: rideData['pickupLocation'] ?? '',
        destinationAddress: rideData['destination'] ?? '',
        distance: (rideData['distance'] ?? 0.0).toDouble(),
        baseFare: (rideData['baseFare'] ?? 0.0).toDouble(),
        perKmRate: (rideData['perKmRate'] ?? 0.0).toDouble(),
        perMinRate: (rideData['perMinRate'] ?? 0.0).toDouble(),
        totalCost: (rideData['price'] ?? 0.0).toDouble(),
        appCommission: (rideData['appCommission'] ?? 0.0).toDouble(),
        driverEarnings: (rideData['driverEarnings'] ?? 0.0).toDouble(),
        timestamp: DateTime.parse(rideData['createdAt']),
        status: rideData['status'] ?? 'pending',
        stops: List<Map<String, dynamic>>.from(rideData['stops'] ?? []),
      );
      
      // Store in offline data for later sync
      _offlineData['ride_${ride.id}'] = {
        'type': 'ride',
        'data': ride.toMap(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'operation': 'create',
      };
      
      await _saveOfflineData();
      return true;
    } catch (e) {
      Logger.error('Failed to create ride offline: $e', error: e);
      return false;
    }
  }

  /// Execute update ride operation
  Future<bool> _executeUpdateRide(OfflineOperation operation) async {
    try {
      final rideData = operation.data;
      final rideId = rideData['id'];
      
      if (_offlineData.containsKey('ride_$rideId')) {
        // Update existing offline ride data
        final existingData = _offlineData['ride_$rideId']!;
        existingData['data'].addAll(rideData);
        existingData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
        existingData['operation'] = 'update';
        
        await _saveOfflineData();
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Failed to update ride offline: $e', error: e);
      return false;
    }
  }

  /// Execute delete ride operation
  Future<bool> _executeDeleteRide(OfflineOperation operation) async {
    try {
      final rideData = operation.data;
      final rideId = rideData['id'];
      
      if (_offlineData.containsKey('ride_$rideId')) {
        // Mark for deletion
        _offlineData['ride_$rideId']!['operation'] = 'delete';
        _offlineData['ride_$rideId']!['timestamp'] = DateTime.now().millisecondsSinceEpoch;
        
        await _saveOfflineData();
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Failed to delete ride offline: $e', error: e);
      return false;
    }
  }

  /// Execute create user operation
  Future<bool> _executeCreateUser(OfflineOperation operation) async {
    try {
      final userData = operation.data;
      
      // Store in offline data for later sync
      _offlineData['user_${userData['id']}'] = {
        'type': 'user',
        'data': userData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'operation': 'create',
      };
      
      await _saveOfflineData();
      return true;
    } catch (e) {
      Logger.error('Failed to create user offline: $e', error: e);
      return false;
    }
  }

  /// Execute update user operation
  Future<bool> _executeUpdateUser(OfflineOperation operation) async {
    try {
      final userData = operation.data;
      final userId = userData['id'];
      
      if (_offlineData.containsKey('user_$userId')) {
        // Update existing offline user data
        final existingData = _offlineData['user_$userId']!;
        existingData['data'].addAll(userData);
        existingData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
        existingData['operation'] = 'update';
        
        await _saveOfflineData();
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Failed to update user offline: $e', error: e);
      return false;
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSync() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Calculate approximate storage size
  int _calculateStorageSize() {
    try {
      final queueSize = jsonEncode(_offlineQueue).length;
      final dataSize = jsonEncode(_offlineData).length;
      return queueSize + dataSize;
    } catch (e) {
      return 0;
    }
  }

  /// Dispose resources
  void dispose() {
    _offlineQueue.clear();
    _offlineData.clear();
    _isInitialized = false;
  }
}

/// Represents an offline operation to be executed when back online
class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final Map<String, dynamic> data;
  final DateTime? timestamp;
  int retryCount;
  final int maxRetries;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    this.timestamp,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  /// Create from JSON
  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: OfflineOperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => OfflineOperationType.unknown,
      ),
      data: json['data'] ?? {},
      timestamp: json['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
      retryCount: json['retryCount'] ?? 0,
      maxRetries: json['maxRetries'] ?? 3,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp?.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
    };
  }

  /// Create a copy with incremented retry count
  OfflineOperation incrementRetry() {
    return OfflineOperation(
      id: id,
      type: type,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount + 1,
      maxRetries: maxRetries,
    );
  }

  /// Check if operation can be retried
  bool get canRetry => retryCount < maxRetries;
}

/// Types of offline operations
enum OfflineOperationType {
  createRide,
  updateRide,
  deleteRide,
  createUser,
  updateUser,
  unknown,
}

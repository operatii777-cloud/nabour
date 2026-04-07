import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:nabour_app/utils/logger.dart';

// IMPLEMENTARE ROBUST HTTP CLIENT - PERFORMANCE OPTIMIZATION
class RobustHttpClient {
  static final RobustHttpClient _instance = RobustHttpClient._internal();
  factory RobustHttpClient() => _instance;
  RobustHttpClient._internal();

  // Connection pooling
  static const int _maxConnections = 10;
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _idleTimeout = Duration(minutes: 5);
  
  // Cache configuration
  static const Duration _defaultCacheTTL = Duration(minutes: 15);
  static const int _maxCacheSize = 100; // MB
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  
  // HTTP client with connection pooling
  late http.Client _httpClient;
  final Map<String, _ConnectionPool> _connectionPools = {};
  final Map<String, _CacheEntry> _cache = {};
  
  // Performance metrics
  final Map<String, _PerformanceMetric> _performanceMetrics = {};
  
  // Timer management
  Timer? _cacheCleanupTimer;
  
  Future<void> initialize() async {
    _httpClient = http.Client();
    
    // Initialize connection pools for different domains
    _initializeConnectionPools();
    
    // Start cache cleanup timer
    _startCacheCleanupTimer();
    
    Logger.info('Robust HTTP Client initialized successfully');
  }
  
  void _initializeConnectionPools() {
    final domains = [
      'api.mapbox.com',
      'api.openai.com',
      'firebase.googleapis.com',
      'maps.googleapis.com',
    ];
    
    for (final domain in domains) {
      _connectionPools[domain] = _ConnectionPool(
        maxConnections: _maxConnections,
        connectionTimeout: _connectionTimeout,
        idleTimeout: _idleTimeout,
      );
    }
  }
  
  void _startCacheCleanupTimer() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredCache();
      _cleanupIdleConnections();
    });
  }
  
  /// Executes an HTTP request with connection pooling, caching, and retry logic
  Future<http.Response> executeRequest(
    http.BaseRequest request, {
    Duration? cacheTTL,
    bool useCache = true,
    int? maxRetries,
  }) async {
    final startTime = DateTime.now();
    final cacheKey = _generateCacheKey(request);
    
    // Try cache first if enabled
    if (useCache && request.method == 'GET') {
      final cachedResponse = _getCachedResponse(cacheKey);
      if (cachedResponse != null) {
        _recordPerformanceMetric('cache_hit', startTime);
        return cachedResponse;
      }
    }
    
    // Execute request with retry logic
    final response = await _executeWithRetry(
      request,
      maxRetries ?? _maxRetries,
    );
    
    // Cache successful GET responses
    if (useCache && request.method == 'GET' && response.statusCode == 200) {
      _cacheResponse(cacheKey, response, cacheTTL ?? _defaultCacheTTL);
    }
    
    _recordPerformanceMetric('request_success', startTime);
    return response;
  }
  
  /// Executes a request with exponential backoff retry logic
  Future<http.Response> _executeWithRetry(
    http.BaseRequest request,
    int maxRetries,
  ) async {
    Exception? lastException;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _executeSingleRequest(request);
        
        // Check if response indicates retry is needed
        if (_shouldRetry(response.statusCode)) {
          if (attempt == maxRetries) {
            return response; // Return last response even if it's an error
          }
          
          final delay = _calculateRetryDelay(attempt);
          await Future.delayed(delay);
          continue;
        }
        
        return response;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt == maxRetries) {
          throw lastException;
        }
        
        // Don't retry on certain types of errors
        if (e is SocketException || e is HttpException) {
          final delay = _calculateRetryDelay(attempt);
          await Future.delayed(delay);
          continue;
        }
        
        // For other errors, don't retry
        throw lastException;
      }
    }
    
    throw lastException ?? Exception('Max retries exceeded');
  }
  
  /// Executes a single HTTP request using connection pooling
  Future<http.Response> _executeSingleRequest(http.BaseRequest request) async {
    final uri = request.url;
    final domain = uri.host;
    
    // Get connection pool for domain
    final pool = _connectionPools[domain];
    if (pool != null) {
      return await pool.executeRequest(_httpClient, request);
    }
    
    // Fallback to direct execution
    return await _httpClient.send(request).then(http.Response.fromStream);
  }
  
  /// Determines if a response status code indicates retry is needed
  bool _shouldRetry(int statusCode) {
    return statusCode >= 500 || statusCode == 429; // Server errors or rate limit
  }
  
  /// Calculates retry delay with exponential backoff
  Duration _calculateRetryDelay(int attempt) {
    final delay = _baseRetryDelay.inMilliseconds * (1 << attempt);
    return Duration(milliseconds: delay);
  }
  
  /// Generates cache key for a request
  String _generateCacheKey(http.BaseRequest request) {
    final uri = request.url.toString();
    final method = request.method;
    final headers = request.headers.entries
        .where((e) => e.key.toLowerCase() != 'authorization')
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    
    return '$method:$uri:$headers';
  }
  
  /// Gets cached response if available and not expired
  http.Response? _getCachedResponse(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry == null) return null;
    
    if (DateTime.now().isAfter(entry.expiryTime)) {
      _cache.remove(cacheKey);
      return null;
    }
    
    return entry.response;
  }
  
  /// Caches a response with TTL
  void _cacheResponse(String cacheKey, http.Response response, Duration ttl) {
    // Check cache size limit
    if (_getCacheSize() > _maxCacheSize) {
      _evictOldestCacheEntries();
    }
    
    _cache[cacheKey] = _CacheEntry(
      response: response,
      expiryTime: DateTime.now().add(ttl),
      size: response.bodyBytes.length,
    );
  }
  
  /// Gets current cache size in MB
  int _getCacheSize() {
    int totalSize = 0;
    for (final entry in _cache.values) {
      totalSize += entry.size;
    }
    return totalSize ~/ (1024 * 1024); // Convert to MB
  }
  
  /// Evicts oldest cache entries to maintain size limit
  void _evictOldestCacheEntries() {
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.expiryTime.compareTo(b.value.expiryTime));
    
    while (_getCacheSize() > _maxCacheSize && sortedEntries.isNotEmpty) {
      final oldest = sortedEntries.removeAt(0);
      _cache.remove(oldest.key);
    }
  }
  
  /// Cleans up expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiryTime));
  }
  
  /// Cleans up idle connections
  void _cleanupIdleConnections() {
    for (final pool in _connectionPools.values) {
      pool.cleanupIdleConnections();
    }
  }
  
  /// Records performance metrics
  void _recordPerformanceMetric(String operation, DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    final metric = _performanceMetrics[operation] ?? _PerformanceMetric();
    metric.addSample(duration);
    _performanceMetrics[operation] = metric;
  }
  
  /// Gets performance statistics
  Map<String, Map<String, dynamic>> getPerformanceStats() {
    final stats = <String, Map<String, dynamic>>{};
    
    for (final entry in _performanceMetrics.entries) {
      stats[entry.key] = {
        'count': entry.value.count,
        'averageDuration': entry.value.averageDuration.inMilliseconds,
        'minDuration': entry.value.minDuration.inMilliseconds,
        'maxDuration': entry.value.maxDuration.inMilliseconds,
      };
    }
    
    return stats;
  }
  
  /// Clears cache
  void clearCache() {
    _cache.clear();
    Logger.debug('HTTP Client cache cleared');
  }
  
  /// Disposes resources
  void dispose() {
    // Cancel cache cleanup timer
    _cacheCleanupTimer?.cancel();
    
    // Close HTTP client
    _httpClient.close();
    
    // Clear all data
    _cache.clear();
    _connectionPools.clear();
    
    Logger.debug('Robust HTTP Client disposed');
  }
}

/// Connection pool for managing HTTP connections to specific domains
class _ConnectionPool {
  final int maxConnections;
  final Duration connectionTimeout;
  final Duration idleTimeout;
  
  final List<_Connection> _connections = [];
  final Queue<_PendingRequest> _pendingRequests = Queue();
  
  _ConnectionPool({
    required this.maxConnections,
    required this.connectionTimeout,
    required this.idleTimeout,
  });
  
  /// Executes a request using connection pooling
  Future<http.Response> executeRequest(
    http.Client client,
    http.BaseRequest request,
  ) async {
    // Try to get an available connection
    final connection = _getAvailableConnection();
    if (connection != null) {
      return await _executeOnConnection(connection, request);
    }
    
    // If no connections available and under limit, create new one
    if (_connections.length < maxConnections) {
      final newConnection = await _createConnection(client, request);
      return await _executeOnConnection(newConnection, request);
    }
    
    // Queue request if at connection limit
    final completer = Completer<http.Response>();
    _pendingRequests.add(_PendingRequest(request, completer));
    
    return completer.future;
  }
  
  /// Gets an available connection from the pool
  _Connection? _getAvailableConnection() {
    for (final connection in _connections) {
      if (!connection.isInUse && !connection.isExpired) {
        connection.markInUse();
        return connection;
      }
    }
    return null;
  }
  
  /// Creates a new connection
  Future<_Connection> _createConnection(
    http.Client client,
    http.BaseRequest request,
  ) async {
    final connection = _Connection(
      client: client,
      createdAt: DateTime.now(),
      timeout: connectionTimeout,
      idleTimeout: idleTimeout,
    );
    
    _connections.add(connection);
    return connection;
  }
  
  /// Executes a request on a specific connection
  Future<http.Response> _executeOnConnection(
    _Connection connection,
    http.BaseRequest request,
  ) async {
    try {
      final response = await connection.executeRequest(request);
      return response;
    } finally {
      connection.markAvailable();
      _processPendingRequests();
    }
  }
  
  /// Processes pending requests when connections become available
  void _processPendingRequests() {
    while (_pendingRequests.isNotEmpty) {
      final pending = _pendingRequests.removeFirst();
      final connection = _getAvailableConnection();
      
      if (connection != null) {
        _executeOnConnection(connection, pending.request)
            .then(pending.completer.complete)
            .catchError(pending.completer.completeError);
      } else {
        // Re-queue if no connections available
        _pendingRequests.addFirst(pending);
        break;
      }
    }
  }
  
  /// Cleans up idle connections
  void cleanupIdleConnections() {
    _connections.removeWhere((connection) => connection.isExpired);
  }
}

/// Represents a single HTTP connection
class _Connection {
  final http.Client client;
  final DateTime createdAt;
  final Duration timeout;
  final Duration idleTimeout;
  
  bool _isInUse = false;
  // DateTime? _lastUsed; // Removed unused field
  
  _Connection({
    required this.client,
    required this.createdAt,
    required this.timeout,
    required this.idleTimeout,
  });
  
  bool get isInUse => _isInUse;
  bool get isExpired => DateTime.now().isAfter(createdAt.add(timeout));
  
  void markInUse() {
    _isInUse = true;
    // _lastUsed = DateTime.now(); // Removed unused field
  }
  
  void markAvailable() {
    _isInUse = false;
    // _lastUsed = DateTime.now(); // Removed unused field
  }
  
  Future<http.Response> executeRequest(http.BaseRequest request) async {
    return await client.send(request).then(http.Response.fromStream);
  }
}

/// Represents a pending request waiting for a connection
class _PendingRequest {
  final http.BaseRequest request;
  final Completer<http.Response> completer;
  
  _PendingRequest(this.request, this.completer);
}

/// Cache entry for HTTP responses
class _CacheEntry {
  final http.Response response;
  final DateTime expiryTime;
  final int size; // Size in bytes
  
  _CacheEntry({
    required this.response,
    required this.expiryTime,
    required this.size,
  });
}

/// Performance metric tracking
class _PerformanceMetric {
  int count = 0;
  Duration totalDuration = Duration.zero;
  Duration minDuration = const Duration(days: 365);
  Duration maxDuration = Duration.zero;
  
  void addSample(Duration duration) {
    count++;
    totalDuration += duration;
    
    if (duration < minDuration) minDuration = duration;
    if (duration > maxDuration) maxDuration = duration;
  }
  
  Duration get averageDuration {
    if (count == 0) return Duration.zero;
    return Duration(microseconds: totalDuration.inMicroseconds ~/ count);
  }
}

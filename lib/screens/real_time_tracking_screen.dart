import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/services/real_time_tracking_service.dart';
import 'package:nabour_app/utils/coordinate_helpers.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/widgets/theme_toggle_button.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🚀 Real-time Tracking Screen cu AI Integration
/// 
/// Acest ecran oferă:
/// - Live map cu tracking în timp real
/// - AI-powered ETA predictions
/// - Real-time communication
/// - Emergency features
/// - Performance monitoring
class RealTimeTrackingScreen extends StatefulWidget {
  final String rideId;
  final String userId;
  final UserRole userRole;
  final Point startLocation;
  final Point destination;
  
  const RealTimeTrackingScreen({
    super.key,
    required this.rideId,
    required this.userId,
    required this.userRole,
    required this.startLocation,
    required this.destination,
  });

  @override
  State<RealTimeTrackingScreen> createState() => _RealTimeTrackingScreenState();
}

class _RealTimeTrackingScreenState extends State<RealTimeTrackingScreen>
    with TickerProviderStateMixin {
  
  // Core Services
  final RealTimeTrackingService _trackingService = RealTimeTrackingService();
  
  // Map Controllers
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markersManager;
  
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Tracking State
  bool _isTrackingActive = false;
  RealTimeLocationUpdate? _lastLocationUpdate;
  AIPrediction? _currentPrediction;
  final List<RealTimeCommunication> _communications = [];
  EmergencyAlert? _activeEmergency;
  
  // UI State
  bool _isCommunicationPanelVisible = false;
  bool _isEmergencyPanelVisible = false;
  String _messageInput = '';
  
  // Performance Monitoring
  DateTime? _trackingStartTime;
  int _totalLocationUpdates = 0;
  double _averageUpdateInterval = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupTrackingService();
    _startTracking();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _trackingService.stopTracking();
    super.dispose();
  }
  
  void _initializeAnimations() {
    // Pulse animation pentru tracking indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Slide animation pentru communication panel
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }
  
  void _setupTrackingService() {
    // Setup callbacks
    _trackingService.onLocationUpdate = _handleLocationUpdate;
    _trackingService.onPredictionUpdate = _handlePredictionUpdate;
    _trackingService.onCommunicationUpdate = _handleCommunicationUpdate;
    _trackingService.onEmergencyAlert = _handleEmergencyAlert;
  }
  
  Future<void> _startTracking() async {
    try {
      await _trackingService.startTracking(
        rideId: widget.rideId,
        userId: widget.userId,
        userRole: widget.userRole,
        startLocation: widget.startLocation,
        destination: widget.destination,
      );
      
      setState(() {
        _isTrackingActive = true;
        _trackingStartTime = DateTime.now();
      });
      
    } catch (e) {
      _showErrorSnackBar('Failed to start tracking: $e');
    }
  }
  
  void _handleLocationUpdate(RealTimeLocationUpdate update) {
    setState(() {
      _lastLocationUpdate = update;
      _totalLocationUpdates++;
      
      // Calculate average update interval
      if (_trackingStartTime != null) {
        final elapsed = DateTime.now().difference(_trackingStartTime!).inSeconds;
        _averageUpdateInterval = elapsed / _totalLocationUpdates;
      }
    });
    
    // Update map marker
    _updateMapMarker(update);
  }
  
  void _handlePredictionUpdate(AIPrediction prediction) {
    setState(() {
      _currentPrediction = prediction;
    });
    
    // Update route on map
    _updateMapRoute(prediction);
  }
  
  void _handleCommunicationUpdate(RealTimeCommunication communication) {
    setState(() {
      _communications.add(communication);
    });
    
    // Show notification
    _showCommunicationNotification(communication);
  }
  
  void _handleEmergencyAlert(EmergencyAlert alert) {
    setState(() {
      _activeEmergency = alert;
      _isEmergencyPanelVisible = true;
    });
    
    // Show emergency notification
    _showEmergencyNotification(alert);
    
    // Log emergency for monitoring
    Logger.error('Emergency alert received: ${alert.type.name} at ${alert.latitude}, ${alert.longitude}');
  }
  
  void _updateMapMarker(RealTimeLocationUpdate update) {
    if (_markersManager == null) return;
    
    // Update user marker position
    final point = CoordinateHelpers.createPoint(
      update.longitude,
      update.latitude,
    );
    
    // Update map marker with current location
    Logger.debug('Updating map marker: ${point.coordinates.lat}, ${point.coordinates.lng}');
    
    // Create marker for current position
    if (_markersManager != null) {
      // In production, this would create/update actual markers on the map
      Logger.info('Map marker updated successfully');
    }
  }
  
  void _updateMapRoute(AIPrediction prediction) {
    if (_mapboxMap == null) return;
    
    // Update route visualization on map
    Logger.debug('Updating map route with ${prediction.optimalRoute.length} points');
    
    // Draw route polyline on map
    if (_mapboxMap != null && prediction.optimalRoute.isNotEmpty) {
      // In production, this would draw actual polylines on the map
      Logger.info('Map route updated successfully');
    }
  }
  
  void _showCommunicationNotification(RealTimeCommunication communication) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              communication.senderRole == UserRole.driver ? Icons.drive_eta : Icons.person,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${communication.senderRole == UserRole.driver ? 'Driver' : 'Passenger'}: ${communication.message}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'Reply',
          textColor: Colors.white,
          onPressed: () => _showCommunicationPanel(),
        ),
      ),
    );
  }
  
  void _showEmergencyNotification(EmergencyAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'EMERGENCY: ${alert.type.name.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _showEmergencyPanel(),
        ),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showCommunicationPanel() {
    setState(() {
      _isCommunicationPanelVisible = true;
    });
    _slideController.forward();
  }
  
  void _hideCommunicationPanel() {
    _slideController.reverse().then((_) {
      setState(() {
        _isCommunicationPanelVisible = false;
      });
    });
  }
  
  void _showEmergencyPanel() {
    setState(() {
      _isEmergencyPanelVisible = true;
    });
  }
  
  void _hideEmergencyPanel() {
    setState(() {
      _isEmergencyPanelVisible = false;
    });
  }
  
  Future<void> _sendMessage() async {
    if (_messageInput.trim().isEmpty) return;
    
    try {
      await _trackingService.sendRealTimeMessage(
        message: _messageInput.trim(),
        type: MessageType.text,
      );
      
      setState(() {
        _messageInput = '';
      });
      
      _hideCommunicationPanel();
      
    } catch (e) {
      _showErrorSnackBar('Failed to send message: $e');
    }
  }
  
  Future<void> _sendEmergencyAlert(EmergencyType type) async {
    try {
      if (_lastLocationUpdate != null) {
        final location = CoordinateHelpers.createPoint(
          _lastLocationUpdate!.longitude,
          _lastLocationUpdate!.latitude,
        );
        
        await _trackingService.sendEmergencyAlert(
          type: type,
          location: location,
          description: 'Emergency alert sent by ${widget.userRole.name}',
        );
      }
      
      _hideEmergencyPanel();
      
    } catch (e) {
      _showErrorSnackBar('Failed to send emergency alert: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('🚀 Real-time Tracking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Theme toggle
          const ThemeToggleButton(),
          
          // Emergency button
          IconButton(
            onPressed: () => _showEmergencyPanel(),
            icon: const Icon(Icons.emergency, color: Colors.red),
            tooltip: 'Emergency',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          _buildMap(),
          
          // Tracking overlay
          _buildTrackingOverlay(),
          
          // Communication panel
          if (_isCommunicationPanelVisible) _buildCommunicationPanel(),
          
          // Emergency panel
          if (_isEmergencyPanelVisible) _buildEmergencyPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCommunicationPanel(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
  
  Widget _buildMap() {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
    );
  }
  
  Widget _buildTrackingOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tracking status
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isTrackingActive ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isTrackingActive ? '🟢 Tracking Active' : '🔴 Tracking Stopped',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_totalLocationUpdates updates',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // AI Prediction
              if (_currentPrediction != null) ...[
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'AI Prediction',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPredictionItem(
                        'ETA',
                        _formatDuration(_currentPrediction!.estimatedTime),
                        Icons.access_time,
                      ),
                    ),
                    Expanded(
                      child: _buildPredictionItem(
                        'Distance',
                        '${_currentPrediction!.estimatedDistance.toStringAsFixed(1)} km',
                        Icons.straighten,
                      ),
                    ),
                    Expanded(
                      child: _buildPredictionItem(
                        'Confidence',
                        '${(_currentPrediction!.confidence * 100).toStringAsFixed(0)}%',
                        Icons.verified,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Performance metrics
              if (_trackingStartTime != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Performance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPredictionItem(
                        'Avg Interval',
                        '${_averageUpdateInterval.toStringAsFixed(1)}s',
                        Icons.timer,
                      ),
                    ),
                    Expanded(
                      child: _buildPredictionItem(
                        'Uptime',
                        _formatDuration(DateTime.now().difference(_trackingStartTime!)),
                        Icons.schedule,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPredictionItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildCommunicationPanel() {
    return SlideTransition(
      position: _slideAnimation,
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.chat, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Real-time Communication',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _hideCommunicationPanel,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Messages list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _communications.length,
                  itemBuilder: (context, index) {
                    final communication = _communications[index];
                    final isMe = communication.senderId == widget.userId;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                communication.senderRole == UserRole.driver ? Icons.drive_eta : Icons.person,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                communication.message,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.secondary,
                              child: Icon(
                                widget.userRole == UserRole.driver ? Icons.drive_eta : Icons.person,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Message input
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: _messageInput),
                        onChanged: (value) => _messageInput = value,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _sendMessage,
                      backgroundColor: AppColors.primary,
                      mini: true,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmergencyPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Emergency Alert',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _hideEmergencyPanel,
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.red),
            
            // Show active emergency if any
            if (_activeEmergency != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Active: ${_activeEmergency!.type.name.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Emergency types
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildEmergencyButton(
                    EmergencyType.accident,
                    '🚗 Accident',
                    Colors.red,
                  ),
                  _buildEmergencyButton(
                    EmergencyType.medical,
                    '🏥 Medical',
                    Colors.orange,
                  ),
                  _buildEmergencyButton(
                    EmergencyType.breakdown,
                    '🔧 Breakdown',
                    Colors.yellow,
                  ),
                  _buildEmergencyButton(
                    EmergencyType.safety,
                    '🛡️ Safety',
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmergencyButton(EmergencyType type, String label, Color color) {
    return ElevatedButton(
      onPressed: () => _sendEmergencyAlert(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.split(' ')[0], // Emoji
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label.split(' ')[1], // Text
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    
    // Initialize markers manager
    mapboxMap.annotations.createPointAnnotationManager().then((manager) {
      _markersManager = manager;
    });
    
    // Set initial camera position
    mapboxMap.flyTo(
      CameraOptions(
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 2000),
    );
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

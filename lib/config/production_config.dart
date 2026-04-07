import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';

/// Production configuration and deployment management
class ProductionConfig {
  static const String _configKey = 'production_config';
  static const String _featureFlagsKey = 'feature_flags';
  static const String _deploymentKey = 'deployment_info';
  
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  
  // Environment configuration
  Environment _currentEnvironment = Environment.development;
  final Map<String, dynamic> _config = {};
  final Map<String, bool> _featureFlags = {};
  final Map<String, dynamic> _deploymentInfo = {};
  
  // Configuration validation
  bool _isValid = false;
  final List<String> _validationErrors = [];

  /// Current environment
  Environment get currentEnvironment => _currentEnvironment;
  
  /// Check if configuration is valid
  bool get isValid => _isValid;
  
  /// Get validation errors
  List<String> get validationErrors => List<String>.from(_validationErrors);
  
  /// Check if running in production
  bool get isProduction => _currentEnvironment == Environment.production;
  
  /// Check if running in staging
  bool get isStaging => _currentEnvironment == Environment.staging;

  /// Initialize production configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Detect environment
      await _detectEnvironment();
      
      // Load configuration
      await _loadConfiguration();
      
      // Load feature flags
      await _loadFeatureFlags();
      
      // Load deployment info
      await _loadDeploymentInfo();
      
      // Validate configuration
      await _validateConfiguration();
      
      _isInitialized = true;
    } catch (e) {
      Logger.error('Failed to initialize production config: $e', error: e);
      _validationErrors.add('Initialization failed: $e');
    }
  }

  /// Get configuration value
  dynamic getConfig(String key, {dynamic defaultValue}) {
    return _config[key] ?? defaultValue;
  }

  /// Set configuration value
  Future<void> setConfig(String key, dynamic value) async {
    _config[key] = value;
    await _saveConfiguration();
  }

  /// Check if feature flag is enabled
  bool isFeatureEnabled(String feature) {
    return _featureFlags[feature] ?? false;
  }

  /// Enable/disable feature flag
  Future<void> setFeatureFlag(String feature, bool enabled) async {
    _featureFlags[feature] = enabled;
    await _saveFeatureFlags();
  }

  /// Get deployment information
  Map<String, dynamic> getDeploymentInfo() {
    return Map<String, dynamic>.from(_deploymentInfo);
  }

  /// Update deployment information
  Future<void> updateDeploymentInfo(Map<String, dynamic> info) async {
    _deploymentInfo.addAll(info);
    await _saveDeploymentInfo();
  }

  /// Get API endpoints for current environment
  Map<String, String> getApiEndpoints() {
    switch (_currentEnvironment) {
              case Environment.development:
          return {
            'base_url': 'https://dev-api.friendsride.com',
            'websocket_url': 'wss://dev-ws.friendsride.com',
            'cdn_url': 'https://dev-cdn.friendsride.com',
          };
        case Environment.staging:
          return {
            'base_url': 'https://staging-api.friendsride.com',
            'websocket_url': 'wss://staging-ws.friendsride.com',
            'cdn_url': 'https://staging-cdn.friendsride.com',
          };
        case Environment.production:
          return {
            'base_url': 'https://api.friendsride.com',
            'websocket_url': 'wss://ws.friendsride.com',
            'cdn_url': 'https://cdn.friendsride.com',
          };
    }
  }

  /// Get Firebase configuration for current environment
  Map<String, dynamic> getFirebaseConfig() {
    switch (_currentEnvironment) {
              case Environment.development:
          return {
            'project_id': 'friendsride-dev',
            'api_key': 'dev-api-key',
            'auth_domain': 'friendsride-dev.firebaseapp.com',
            'storage_bucket': 'friendsride-dev.appspot.com',
            'messaging_sender_id': '123456789',
            'app_id': 'dev-app-id',
          };
        case Environment.staging:
          return {
            'project_id': 'friendsride-staging',
            'api_key': 'staging-api-key',
            'auth_domain': 'friendsride-staging.firebaseapp.com',
            'storage_bucket': 'friendsride-staging.appspot.com',
            'messaging_sender_id': '987654321',
            'app_id': 'staging-app-id',
          };
        case Environment.production:
          return {
            'project_id': 'friendsride-prod',
            'api_key': 'prod-api-key',
            'auth_domain': 'friendsride-prod.firebaseapp.com',
            'storage_bucket': 'friendsride-prod.appspot.com',
            'messaging_sender_id': '555666777',
            'app_id': 'prod-app-id',
          };
    }
  }

  /// Get Mapbox configuration for current environment
  Map<String, dynamic> getMapboxConfig() {
    switch (_currentEnvironment) {
              case Environment.development:
          return {
            'access_token': 'dev-mapbox-token',
            'style_url': 'mapbox://styles/mapbox/streets-v11',
            'tile_server': 'https://api.mapbox.com',
          };
        case Environment.staging:
          return {
            'access_token': 'staging-mapbox-token',
            'style_url': 'mapbox://styles/mapbox/streets-v11',
            'tile_server': 'https://api.mapbox.com',
          };
        case Environment.production:
          return {
            'access_token': 'prod-mapbox-token',
            'style_url': 'mapbox://styles/mapbox/streets-v11',
            'tile_server': 'https://api.mapbox.com',
          };
    }
  }

  /// Get logging configuration
  Map<String, dynamic> getLoggingConfig() {
    return {
      'level': isProduction ? 'warning' : 'debug',
      'enable_console_logging': !isProduction,
      'enable_file_logging': true,
      'enable_remote_logging': isProduction,
      'max_file_size_mb': 10,
      'max_files': 5,
      'remote_endpoint': '${getApiEndpoints()['base_url']}/logs',
    };
  }

  /// Get analytics configuration
  Map<String, dynamic> getAnalyticsConfig() {
    return {
      'enabled': true,
      'tracking_id': isProduction ? 'prod-tracking-id' : 'dev-tracking-id',
      'sample_rate': isProduction ? 100 : 10,
      'enable_debug': !isProduction,
      'enable_crash_reporting': true,
      'enable_performance_monitoring': true,
    };
  }

  /// Get security configuration
  Map<String, dynamic> getSecurityConfig() {
    return {
      'enable_ssl_pinning': isProduction,
      'enable_certificate_transparency': isProduction,
      'enable_biometric_auth': true,
      'session_timeout_minutes': isProduction ? 30 : 120,
      'max_login_attempts': 5,
      'lockout_duration_minutes': 15,
      'enable_audit_logging': isProduction,
    };
  }

  /// Get performance configuration
  Map<String, dynamic> getPerformanceConfig() {
    return {
      'enable_performance_monitoring': true,
      'memory_threshold_mb': isProduction ? 150.0 : 200.0,
      'cpu_threshold_percent': isProduction ? 70.0 : 80.0,
      'response_time_threshold_ms': isProduction ? 3000 : 5000,
      'enable_caching': true,
      'cache_ttl_seconds': isProduction ? 300 : 60,
      'enable_compression': true,
      'enable_lazy_loading': true,
    };
  }

  /// Get feature flags configuration
  Map<String, dynamic> getFeatureFlagsConfig() {
    return {
      'voice_commands': true,
      'offline_mode': isProduction,
      'advanced_analytics': isProduction,
      'beta_features': !isProduction,
      'debug_tools': !isProduction,
      'performance_monitoring': true,
      'crash_reporting': true,
      'user_feedback': true,
    };
  }

  /// Detect current environment
  Future<void> _detectEnvironment() async {
    try {
      // Check for environment variables
      const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
      
      switch (environment.toLowerCase()) {
        case 'production':
          _currentEnvironment = Environment.production;
          break;
        case 'staging':
          _currentEnvironment = Environment.staging;
          break;
        case 'development':
        default:
          _currentEnvironment = Environment.development;
          break;
      }
      
      // Override with debug mode if available
      if (kDebugMode && _currentEnvironment == Environment.production) {
        _currentEnvironment = Environment.development;
      }
      
      Logger.debug('Detected environment: $_currentEnvironment');
    } catch (e) {
      Logger.error('Failed to detect environment: $e', error: e);
      _currentEnvironment = Environment.development;
    }
  }

  /// Load configuration from storage
  Future<void> _loadConfiguration() async {
    try {
      final configJson = _prefs.getString(_configKey);
      if (configJson != null) {
        final Map<String, dynamic> data = jsonDecode(configJson);
        _config.addAll(data);
      }
    } catch (e) {
      Logger.error('Failed to load configuration: $e', error: e);
    }
  }

  /// Save configuration to storage
  Future<void> _saveConfiguration() async {
    try {
      final configJson = jsonEncode(_config);
      await _prefs.setString(_configKey, configJson);
    } catch (e) {
      Logger.error('Failed to save configuration: $e', error: e);
    }
  }

  /// Load feature flags from storage
  Future<void> _loadFeatureFlags() async {
    try {
      final flagsJson = _prefs.getString(_featureFlagsKey);
      if (flagsJson != null) {
        final Map<String, dynamic> data = jsonDecode(flagsJson);
        _featureFlags.addAll(data.map((key, value) => MapEntry(key, value as bool)));
      }
      
      // Set default feature flags
      final defaultFlags = getFeatureFlagsConfig();
      for (final entry in defaultFlags.entries) {
        if (!_featureFlags.containsKey(entry.key)) {
          _featureFlags[entry.key] = entry.value as bool;
        }
      }
    } catch (e) {
      Logger.error('Failed to load feature flags: $e', error: e);
    }
  }

  /// Save feature flags to storage
  Future<void> _saveFeatureFlags() async {
    try {
      final flagsJson = jsonEncode(_featureFlags);
      await _prefs.setString(_featureFlagsKey, flagsJson);
    } catch (e) {
      Logger.error('Failed to save feature flags: $e', error: e);
    }
  }

  /// Load deployment info from storage
  Future<void> _loadDeploymentInfo() async {
    try {
      final deploymentJson = _prefs.getString(_deploymentKey);
      if (deploymentJson != null) {
        final Map<String, dynamic> data = jsonDecode(deploymentJson);
        _deploymentInfo.addAll(data);
      }
      
      // Set deployment info
      _deploymentInfo['app_name'] = 'Nabour';
      _deploymentInfo['package_name'] = 'com.friendsride.app';
      _deploymentInfo['version'] = '1.0.0';
      _deploymentInfo['build_number'] = '1';
      _deploymentInfo['deployment_timestamp'] = DateTime.now().toIso8601String();
      _deploymentInfo['environment'] = _currentEnvironment.toString();
    } catch (e) {
      Logger.error('Failed to load deployment info: $e', error: e);
    }
  }

  /// Save deployment info to storage
  Future<void> _saveDeploymentInfo() async {
    try {
      final deploymentJson = jsonEncode(_deploymentInfo);
      await _prefs.setString(_deploymentKey, deploymentJson);
    } catch (e) {
      Logger.error('Failed to save deployment info: $e', error: e);
    }
  }

  /// Validate configuration
  Future<void> _validateConfiguration() async {
    _validationErrors.clear();
    
    try {
      // Check required configuration
      final requiredConfigs = ['api_endpoints', 'firebase_config', 'mapbox_config'];
      for (final config in requiredConfigs) {
        if (!_config.containsKey(config)) {
          _validationErrors.add('Missing required configuration: $config');
        }
      }
      
      // Check environment-specific requirements
      if (isProduction) {
        if (!_config.containsKey('ssl_certificates')) {
          _validationErrors.add('Production requires SSL certificates configuration');
        }
        if (!_config.containsKey('monitoring_endpoints')) {
          _validationErrors.add('Production requires monitoring endpoints configuration');
        }
      }
      
      // Check feature flags
      if (_featureFlags.isEmpty) {
        _validationErrors.add('No feature flags configured');
      }
      
      // Check deployment info
      if (_deploymentInfo.isEmpty) {
        _validationErrors.add('No deployment information available');
      }
      
      _isValid = _validationErrors.isEmpty;
    } catch (e) {
      _validationErrors.add('Configuration validation failed: $e');
      _isValid = false;
    }
  }

  /// Export configuration
  Map<String, dynamic> exportConfiguration() {
    return {
      'environment': _currentEnvironment.toString(),
      'configuration': Map<String, dynamic>.from(_config),
      'feature_flags': Map<String, bool>.from(_featureFlags),
      'deployment_info': Map<String, dynamic>.from(_deploymentInfo),
      'validation': {
        'is_valid': _isValid,
        'errors': List<String>.from(_validationErrors),
      },
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}

/// Environment types
enum Environment {
  development,
  staging,
  production,
}

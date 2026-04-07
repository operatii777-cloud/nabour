// Input Validation for Voice Processing and User Input
// Prevents SQL injection, XSS, command injection, and other security vulnerabilities

import 'logger.dart';

/// Input validator for voice processing and user input
class InputValidator {
  // Maximum input length
  static const int maxAddressLength = 200;
  static const int maxVoiceCommandLength = 500;
  static const int maxMessageLength = 1000;
  
  // Dangerous patterns
  static final List<RegExp> _sqlInjectionPatterns = [
    RegExp(r'(union|select|insert|update|delete|drop|create|alter|exec|execute)', caseSensitive: false),
    RegExp(r'(--|;|/\*|\*/)', caseSensitive: false),
    RegExp(r'(or\s+1\s*=\s*1|and\s+1\s*=\s*1)', caseSensitive: false),
  ];
  
  static final List<RegExp> _xssPatterns = [
    RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'on\w+\s*=', caseSensitive: false),
    RegExp(r'<iframe[^>]*>', caseSensitive: false),
  ];
  
  static final List<RegExp> _commandInjectionPatterns = [
    RegExp(r'[;&|`$(){}[\]<>]', caseSensitive: false),
    RegExp(r'(rm\s+-rf|del\s+/f|format\s+)', caseSensitive: false),
  ];
  
  // Valid characters for addresses (Romanian + English + common symbols)
  static final RegExp _validAddressPattern = RegExp(
    r'^[a-zA-ZăâîșțĂÂÎȘȚ0-9\s\.,\-/()]+$',
    caseSensitive: false,
  );
  
  // Valid characters for voice commands
  static final RegExp _validVoiceCommandPattern = RegExp(
    r'^[a-zA-ZăâîșțĂÂÎȘȚ0-9\s\.,\-!?]+$',
    caseSensitive: false,
  );

  /// Validate voice command input
  static ValidationResult validateVoiceCommand(String input) {
    if (input.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Comanda vocală nu poate fi goală',
      );
    }
    
    if (input.length > maxVoiceCommandLength) {
      return ValidationResult(
        isValid: false,
        error: 'Comanda vocală este prea lungă (max $maxVoiceCommandLength caractere)',
      );
    }
    
    // Check for SQL injection
    for (final pattern in _sqlInjectionPatterns) {
      if (pattern.hasMatch(input)) {
        Logger.warning('SQL injection attempt detected in voice command', tag: 'SECURITY');
        return ValidationResult(
          isValid: false,
          error: 'Comanda conține caractere invalide',
        );
      }
    }
    
    // Check for XSS
    for (final pattern in _xssPatterns) {
      if (pattern.hasMatch(input)) {
        Logger.warning('XSS attempt detected in voice command', tag: 'SECURITY');
        return ValidationResult(
          isValid: false,
          error: 'Comanda conține caractere invalide',
        );
      }
    }
    
    // Check for command injection
    for (final pattern in _commandInjectionPatterns) {
      if (pattern.hasMatch(input)) {
        Logger.warning('Command injection attempt detected in voice command', tag: 'SECURITY');
        return ValidationResult(
          isValid: false,
          error: 'Comanda conține caractere invalide',
        );
      }
    }
    
    // Check valid characters
    if (!_validVoiceCommandPattern.hasMatch(input)) {
      Logger.warning('Invalid characters in voice command', tag: 'SECURITY');
      return ValidationResult(
        isValid: false,
        error: 'Comanda conține caractere invalide',
      );
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate address input
  static ValidationResult validateAddress(String address) {
    if (address.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Adresa nu poate fi goală',
      );
    }
    
    if (address.length > maxAddressLength) {
      return ValidationResult(
        isValid: false,
        error: 'Adresa este prea lungă (max $maxAddressLength caractere)',
      );
    }
    
    // Check for SQL injection
    for (final pattern in _sqlInjectionPatterns) {
      if (pattern.hasMatch(address)) {
        Logger.warning('SQL injection attempt detected in address', tag: 'SECURITY');
        return ValidationResult(
          isValid: false,
          error: 'Adresa conține caractere invalide',
        );
      }
    }
    
    // Check for XSS
    for (final pattern in _xssPatterns) {
      if (pattern.hasMatch(address)) {
        Logger.warning('XSS attempt detected in address', tag: 'SECURITY');
        return ValidationResult(
          isValid: false,
          error: 'Adresa conține caractere invalide',
        );
      }
    }
    
    // Check valid characters
    if (!_validAddressPattern.hasMatch(address)) {
      Logger.warning('Invalid characters in address', tag: 'SECURITY');
      return ValidationResult(
        isValid: false,
        error: 'Adresa conține caractere invalide',
      );
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate geographic coordinates
  static ValidationResult validateCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return ValidationResult(
        isValid: false,
        error: 'Coordonatele nu pot fi nule',
      );
    }
    
    // Validate latitude range (-90 to 90)
    if (latitude < -90 || latitude > 90) {
      Logger.warning('Invalid latitude: $latitude', tag: 'SECURITY');
      return ValidationResult(
        isValid: false,
        error: 'Latitudinea trebuie să fie între -90 și 90',
      );
    }
    
    // Validate longitude range (-180 to 180)
    if (longitude < -180 || longitude > 180) {
      Logger.warning('Invalid longitude: $longitude', tag: 'SECURITY');
      return ValidationResult(
        isValid: false,
        error: 'Longitudinea trebuie să fie între -180 și 180',
      );
    }
    
    // Check for suspicious coordinates (0,0 or very close to it)
    if ((latitude.abs() < 0.001 && longitude.abs() < 0.001) && 
        (latitude != 0.0 || longitude != 0.0)) {
      Logger.warning('Suspicious coordinates: $latitude, $longitude', tag: 'SECURITY');
      return ValidationResult(
        isValid: false,
        error: 'Coordonatele sunt invalide',
      );
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate message input (for chat)
  static ValidationResult validateMessage(String message) {
    if (message.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Mesajul nu poate fi gol',
      );
    }
    
    if (message.length > maxMessageLength) {
      return ValidationResult(
        isValid: false,
        error: 'Mesajul este prea lung (max $maxMessageLength caractere)',
      );
    }
    
    // Check for XSS
    for (final pattern in _xssPatterns) {
      if (pattern.hasMatch(message)) {
        Logger.warning('XSS attempt detected in message', tag: 'SECURITY');
        return ValidationResult(
          isValid: false,
          error: 'Mesajul conține caractere invalide',
        );
      }
    }
    
    return ValidationResult(isValid: true);
  }

  /// Sanitize input (remove dangerous characters)
  static String sanitize(String input) {
    String sanitized = input;
    
    // Remove SQL injection patterns
    for (final pattern in _sqlInjectionPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }
    
    // Remove XSS patterns
    for (final pattern in _xssPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }
    
    // Remove command injection patterns
    for (final pattern in _commandInjectionPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }
    
    // Trim and normalize whitespace
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized;
  }

  /// Rate limiting check (simple implementation)
  static final Map<String, List<DateTime>> _rateLimitMap = {};
  static const int maxRequestsPerMinute = 30;
  static const Duration rateLimitWindow = Duration(minutes: 1);

  /// Check if request is within rate limit
  static bool checkRateLimit(String identifier) {
    final now = DateTime.now();
    final requests = _rateLimitMap[identifier] ?? [];
    
    // Remove old requests outside the window
    final validRequests = requests.where(
      (timestamp) => now.difference(timestamp) < rateLimitWindow,
    ).toList();
    
    if (validRequests.length >= maxRequestsPerMinute) {
      Logger.warning('Rate limit exceeded for: $identifier', tag: 'SECURITY');
      return false;
    }
    
    validRequests.add(now);
    _rateLimitMap[identifier] = validRequests;
    
    return true;
  }

  /// Clear rate limit for identifier
  static void clearRateLimit(String identifier) {
    _rateLimitMap.remove(identifier);
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({
    required this.isValid,
    this.error,
  });
}


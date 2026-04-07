import 'package:nabour_app/config/environment.dart';

/// Grok (xAI) — API OpenAI-compatibil
/// Model: grok-2-latest
/// Docs: https://docs.x.ai/api
class GrokConfig {
  static const String _baseUrl = 'https://api.x.ai/v1/chat/completions';
  static const String _model = 'grok-2-latest';

  static String get apiKey => Environment.grokApiKey;

  static bool get isValid =>
      apiKey.isNotEmpty &&
      !apiKey.contains('PLACEHOLDER') &&
      !apiKey.contains('REPLACE');

  static String get baseUrl => _baseUrl;
  static String get model => _model;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

  static Map<String, dynamic> buildRequestBody(String systemPrompt, String userMessage) => {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 1024,
        'temperature': 0.1,
        'top_p': 0.8,
      };

  static const Duration timeout = Duration(seconds: 20);
}

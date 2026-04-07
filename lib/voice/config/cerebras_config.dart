import 'package:nabour_app/config/environment.dart';

/// Cerebras AI - API OpenAI-compatibil
/// Model: llama-3.3-70b — cel mai ieftin provider (~$0.10/M tokens)
/// Docs: https://inference-docs.cerebras.ai
class CerebrasConfig {
  static const String _baseUrl = 'https://api.cerebras.ai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b';

  static String get apiKey => Environment.cerebrasApiKey;

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

  static const Duration timeout = Duration(seconds: 15);
}

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Căutare GIF (Giphy). Fără cheie în `.env` folosește un set mic de fallback-uri.
class GiphyService {
  GiphyService._();
  static final GiphyService instance = GiphyService._();

  static const _fallbackUrls = <String>[
    'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif',
    'https://media.giphy.com/media/l0MYC0LajbaPoEADu/giphy.gif',
    'https://media.giphy.com/media/26BRv0ThflsHCqDrG/giphy.gif',
  ];

  String? get _apiKey => dotenv.maybeGet('GIPHY_API_KEY')?.trim();

  Future<List<GiphyGif>> search(String query, {int limit = 20}) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      return _fallbackUrls
          .map((u) => GiphyGif(url: u, previewUrl: u, title: 'GIF'))
          .toList();
    }
    final q = query.trim().isEmpty ? 'hello' : query.trim();
    final uri = Uri.https('api.giphy.com', '/v1/gifs/search', {
      'api_key': key,
      'q': q,
      'limit': '$limit',
      'rating': 'g',
    });
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final data = map['data'] as List<dynamic>? ?? [];
      return data.map((raw) {
        final m = raw as Map<String, dynamic>;
        final images = m['images'] as Map<String, dynamic>?;
        final downsized = images?['downsized'] as Map<String, dynamic>?;
        final fixedH = images?['fixed_height_small'] as Map<String, dynamic>?;
        final url = (downsized?['url'] ?? fixedH?['url'] ?? '') as String;
        final prev = (fixedH?['url'] ?? url) as String;
        return GiphyGif(
          url: url.isNotEmpty ? url : prev,
          previewUrl: prev,
          title: (m['title'] as String?) ?? 'GIF',
        );
      }).where((g) => g.url.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }
}

class GiphyGif {
  final String url;
  final String previewUrl;
  final String title;

  const GiphyGif({
    required this.url,
    required this.previewUrl,
    required this.title,
  });
}

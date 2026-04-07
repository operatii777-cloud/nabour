import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nabour_app/utils/logger.dart';

/// Widget pentru GIF picker folosind Giphy API
class GifPickerWidget extends StatefulWidget {
  final Function(String gifUrl, String gifId) onGifSelected;
  final String? giphyApiKey; // Opțional - poate fi null pentru demo

  const GifPickerWidget({
    super.key,
    required this.onGifSelected,
    this.giphyApiKey,
  });

  @override
  State<GifPickerWidget> createState() => _GifPickerWidgetState();
}

class _GifPickerWidgetState extends State<GifPickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _gifs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingGifs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingGifs() async {
    if (widget.giphyApiKey == null) {
      // Fallback: folosim un set de GIF-uri demo
      setState(() {
        _gifs = _getDemoGifs();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        'https://api.giphy.com/v1/gifs/trending?api_key=${widget.giphyApiKey}&limit=25&rating=g',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _gifs = List<Map<String, dynamic>>.from(
            data['data'].map((gif) => {
              'id': gif['id'],
              'url': gif['images']['fixed_height']['url'],
              'preview': gif['images']['fixed_height_small_still']['url'],
            }),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _gifs = _getDemoGifs();
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.warning('Load GIFs failed: $e', tag: 'GifPicker');
      setState(() {
        _gifs = _getDemoGifs();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrendingGifs();
      return;
    }

    if (widget.giphyApiKey == null) {
      // Fallback pentru demo
      setState(() {
        _gifs = _getDemoGifs();
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
        'https://api.giphy.com/v1/gifs/search?api_key=${widget.giphyApiKey}&q=${Uri.encodeComponent(query)}&limit=25&rating=g',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _gifs = List<Map<String, dynamic>>.from(
            data['data'].map((gif) => {
              'id': gif['id'],
              'url': gif['images']['fixed_height']['url'],
              'preview': gif['images']['fixed_height_small_still']['url'],
            }),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _gifs = _getDemoGifs();
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.warning('Search GIFs failed: $e', tag: 'GifPicker');
      setState(() {
        _gifs = _getDemoGifs();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getDemoGifs() {
    // GIF-uri demo pentru când nu există API key
    return [
      {
        'id': 'demo1',
        'url': 'https://media.giphy.com/media/3o7aCTPPm4OHfRLSH6/giphy.gif',
        'preview': 'https://media.giphy.com/media/3o7aCTPPm4OHfRLSH6/giphy.gif',
      },
      {
        'id': 'demo2',
        'url': 'https://media.giphy.com/media/l0MYC0LajbaPoEADu/giphy.gif',
        'preview': 'https://media.giphy.com/media/l0MYC0LajbaPoEADu/giphy.gif',
      },
      {
        'id': 'demo3',
        'url': 'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif',
        'preview': 'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Caută GIF-uri...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadTrendingGifs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _searchGifs,
              onChanged: (value) {
                if (value.isEmpty) {
                  _loadTrendingGifs();
                }
              },
            ),
          ),
          // GIF grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _gifs.isEmpty
                    ? Center(
                        child: Text(
                          'Nu s-au găsit GIF-uri',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _gifs.length,
                        itemBuilder: (context, index) {
                          final gif = _gifs[index];
                          return GestureDetector(
                            onTap: () {
                              widget.onGifSelected(gif['url'], gif['id']);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: gif['preview'] ?? gif['url'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/features/map_moments/map_moment_service.dart';

/// Bottom sheet for composing a new map moment (quick check-in / story).
class PostMomentSheet extends StatefulWidget {
  const PostMomentSheet({
    super.key,
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  @override
  State<PostMomentSheet> createState() => _PostMomentSheetState();
}

class _PostMomentSheetState extends State<PostMomentSheet> {
  final _captionCtl = TextEditingController();
  String? _selectedEmoji;
  bool _posting = false;

  static const _quickEmojis = [
    '📍', '☕', '🎶', '🏋️', '🍕', '📸', '🎉', '💤', '🚀', '❤️',
  ];

  @override
  void dispose() {
    _captionCtl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_posting) return;
    final caption = _captionCtl.text.trim();
    if (caption.isEmpty && _selectedEmoji == null) return;

    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trebuie să fii autentificat ca să postezi un moment.'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }

    setState(() => _posting = true);
    final id = await MapMomentService.instance.post(
      lat: widget.lat,
      lng: widget.lng,
      caption: caption.isNotEmpty ? caption : (_selectedEmoji ?? '📍'),
      emoji: _selectedEmoji,
      ttl: const Duration(minutes: 30),
    );
    if (!mounted) return;
    setState(() => _posting = false);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nu s-a putut publica. Verifică conexiunea și regulile Firestore pentru „map_moments”.',
          ),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Postează un Moment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vizibil pe hartă ~30 minute. O poți șterge oricând din tap pe marcaj.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: _quickEmojis.map((e) {
              final selected = _selectedEmoji == e;
              return GestureDetector(
                onTap: () => setState(() =>
                    _selectedEmoji = selected ? null : e),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: const Color(0xFF7C3AED), width: 2)
                        : null,
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 26)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionCtl,
            maxLength: 120,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ce se întâmplă aici?',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _posting ? null : _post,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _posting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Postează',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

/// Widget pentru emoji picker (stil WhatsApp)
class EmojiPickerWidget extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;
  final VoidCallback? onBackspace;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          onEmojiSelected(emoji.emoji);
        },
        onBackspacePressed: onBackspace,
        config: const Config(
          height: 250,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}


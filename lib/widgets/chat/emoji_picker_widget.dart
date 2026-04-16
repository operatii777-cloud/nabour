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
    final surface = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(color: outline),
        ),
      ),
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          onEmojiSelected(emoji.emoji);
        },
        onBackspacePressed: onBackspace,
        config: Config(
          height: 250,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: surface,
          ),
        ),
      ),
    );
  }
}


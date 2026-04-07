import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/voice/utils/voice_translations.dart';

/// Widget displayed when voice recognition fails [threshold] times in a row.
///
/// Shows an explanatory message and a text field so the user can type their
/// command manually, with a "Retry voice" button to dismiss the fallback.
class VoiceFallbackCard extends StatefulWidget {
  /// Called when the user submits a manual text input.
  final Future<void> Function(String text) onManualInput;

  /// Called when the user wants to retry voice input.
  final VoidCallback onRetry;

  const VoiceFallbackCard({
    super.key,
    required this.onManualInput,
    required this.onRetry,
  });

  @override
  State<VoiceFallbackCard> createState() => _VoiceFallbackCardState();
}

class _VoiceFallbackCardState extends State<VoiceFallbackCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  String _langCode = 'ro';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _langCode = prefs.getString('locale') ?? 'ro';
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onManualInput(text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackMsg = VoiceTranslations.getVoiceFallbackMessage(languageCode: _langCode);
    final inputLabel = VoiceTranslations.getManualInputLabel(languageCode: _langCode);
    final sendLabel = VoiceTranslations.getManualInputSendButton(languageCode: _langCode);
    final retryLabel = VoiceTranslations.getRetryVoiceButton(languageCode: _langCode);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic_off, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fallbackMsg,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: inputLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(sendLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.mic, size: 16),
                label: Text(retryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nabour_app/voice/utils/voice_translations.dart';
import 'package:nabour_app/voice/core/voice_orchestrator.dart';
import 'package:nabour_app/widgets/voice/voice_fallback_card.dart';
import 'package:nabour_app/utils/logger.dart';

/// A panel of quick-action FABs for an active ride.
///
/// Provides three floating-action buttons:
///   • Call driver  (also triggered by voice: "sună șoferul" / "call driver")
///   • Cancel ride  (also triggered by voice: "anulează cursa" / "cancel ride")
///   • Share location (also triggered by voice: "trimite locația" / "share location")
///
/// If STT fails [_failureThreshold] times consecutively the panel replaces the
/// voice hint with [VoiceFallbackCard] so the user can type manually.
class ActiveRideVoicePanel extends StatefulWidget {
  final VoidCallback onCallDriver;
  final VoidCallback onCancelRide;
  final VoidCallback onShareLocation;

  const ActiveRideVoicePanel({
    super.key,
    required this.onCallDriver,
    required this.onCancelRide,
    required this.onShareLocation,
  });

  @override
  State<ActiveRideVoicePanel> createState() => _ActiveRideVoicePanelState();
}

class _ActiveRideVoicePanelState extends State<ActiveRideVoicePanel> {
  static const int _failureThreshold = 2;

  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  bool _isListening = false;
  int _consecutiveFailures = 0;
  bool _showFallback = false;
  String _langCode = 'ro';
  String _localeId = 'ro_RO';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadLanguage();
    _sttAvailable = await _stt.initialize(
      onError: (e) => _onSttError(e.errorMsg),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('locale') ?? 'ro';
      if (mounted) {
        setState(() {
          _langCode = code;
          _localeId = code == 'en' ? 'en_US' : 'ro_RO';
        });
      }
    } catch (_) {}
  }

  void _onSttError(String error) {
    Logger.warning('ActiveRideVoicePanel STT error: $error', tag: 'RIDE_VOICE_PANEL');
    _consecutiveFailures++;
    if (_consecutiveFailures >= _failureThreshold) {
      if (mounted) setState(() => _showFallback = true);
    }
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _startListening() async {
    // Guard: never start while the shared TTS is speaking.
    final orchestrator = VoiceOrchestrator();
    if (orchestrator.isTtsSpeaking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _langCode == 'en'
                ? 'Please wait for the assistant to finish speaking.'
                : 'Așteptați ca asistentul să termine de vorbit.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_sttAvailable || _isListening) return;
    setState(() => _isListening = true);

    await _stt.listen(
      localeId: _localeId,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (!result.finalResult) return;
        final words = result.recognizedWords.trim();
        Logger.debug('ActiveRideVoicePanel result: "$words"', tag: 'RIDE_VOICE_PANEL');

        if (words.isEmpty) {
          _onSttError('empty_result');
          return;
        }

        // Successful recognition → reset failure counter.
        _consecutiveFailures = 0;
        if (mounted) setState(() { _isListening = false; _showFallback = false; });
        _handleCommand(words);
      },
    );
  }

  void _handleCommand(String text) {
    if (VoiceTranslations.matchesCallDriver(text, languageCode: _langCode)) {
      widget.onCallDriver();
    } else if (VoiceTranslations.matchesCancelRide(text, languageCode: _langCode)) {
      widget.onCancelRide();
    } else if (VoiceTranslations.matchesShareLocation(text, languageCode: _langCode)) {
      widget.onShareLocation();
    } else {
      // Unrecognised command counts as a failure.
      _onSttError('no_match: $text');
    }
  }

  Future<void> _handleManualInput(String text) async {
    _consecutiveFailures = 0;
    if (mounted) setState(() => _showFallback = false);
    _handleCommand(text);
  }

  void _retryVoice() {
    _consecutiveFailures = 0;
    if (mounted) setState(() => _showFallback = false);
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showFallback)
          VoiceFallbackCard(
            onManualInput: _handleManualInput,
            onRetry: _retryVoice,
          ),

        // FAB row: call, cancel, share, voice mic
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: Wrap(
            direction: Axis.vertical,
            spacing: 10,
            alignment: WrapAlignment.end,
            children: [
              // Call driver FAB
              _RideActionFab(
                heroTag: 'voice_call_driver',
                icon: Icons.phone,
                label: _langCode == 'en' ? 'Call' : 'Sună',
                color: Colors.blue,
                onPressed: widget.onCallDriver,
              ),

              // Cancel ride FAB
              _RideActionFab(
                heroTag: 'voice_cancel_ride',
                icon: Icons.cancel_outlined,
                label: _langCode == 'en' ? 'Cancel' : 'Anulează',
                color: Colors.red,
                onPressed: widget.onCancelRide,
              ),

              // Share location FAB
              _RideActionFab(
                heroTag: 'voice_share_location',
                icon: Icons.share_location,
                label: _langCode == 'en' ? 'Share' : 'Locație',
                color: Colors.green,
                onPressed: widget.onShareLocation,
              ),

              // Voice command FAB
              if (_sttAvailable)
                _RideActionFab(
                  heroTag: 'voice_mic',
                  icon: _isListening ? Icons.mic : Icons.mic_none,
                  label: _isListening
                      ? (_langCode == 'en' ? 'Listening…' : 'Ascult…')
                      : (_langCode == 'en' ? 'Voice' : 'Voce'),
                  color: _isListening ? Colors.orange : Colors.purple,
                  onPressed: _isListening ? null : _startListening,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small labeled FAB used inside [ActiveRideVoicePanel].
class _RideActionFab extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _RideActionFab({
    required this.heroTag,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

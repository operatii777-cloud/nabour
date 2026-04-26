import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/screens/map_screen.dart';
import 'package:nabour_app/screens/app_warmup_screen.dart';
import 'package:nabour_app/utils/logger.dart';

/// [MapScreen] sub hartă; [AppWarmupScreen] full-screen deasupra până la trage în jos
/// sau „Deschide harta”. La închidere, harta face fly din zoom glob spre locația userului.
///
/// Warmup is removed with an instant [setState] (no opacity animation).
/// On some devices (MIUI + Impeller + Mapbox GL), fading the overlay out
/// could trigger compositor/native issues when the surface is resized.
class MapWithWarmupScreen extends StatefulWidget {
  const MapWithWarmupScreen({super.key});

  @override
  State<MapWithWarmupScreen> createState() => _MapWithWarmupScreenState();
}

class _MapWithWarmupScreenState extends State<MapWithWarmupScreen> {
  bool _showWarmup = true;
  bool _dismissingWarmup = false;

  /// [true] = overlay warmup vizibil; la [false] [MapScreen] lansează fly din spațiu spre user.
  late final ValueNotifier<bool> _warmupOverlayVisible;

  static const String _disclaimerKey = 'nabour_disclaimer_accepted_v1';

  @override
  void initState() {
    super.initState();
    _warmupOverlayVisible = ValueNotifier<bool>(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowDisclaimer();
      _setupAutoDismiss();
    });
  }

  void _setupAutoDismiss() {
    // ✋ DEACTIVATED: User wants the warmup screen to be a manual "presentation"
    // that stays until they decide to open the map.
  }

  @override
  void dispose() {
    _warmupOverlayVisible.dispose();
    super.dispose();
  }

  Future<void> _maybeShowDisclaimer() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_disclaimerKey) ?? false;
      if (seen || !mounted) return;
      await _showDisclaimerSheet();
      await prefs.setBool(_disclaimerKey, true);
    } catch (e) {
      Logger.debug('map_with_warmup disclaimer prefs failed: $e', tag: 'MAP_WARMUP');
    }
  }

  Future<void> _showDisclaimerSheet() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    color: Color(0xFF7C3AED),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.disclaimerNoPaymentsTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.disclaimerNoPaymentsSubtitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.disclaimerNoPaymentsBody,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.disclaimerUsageNotice,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n.disclaimerUnderstood,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismissWarmup() {
    if (!_showWarmup || _dismissingWarmup) return;
    _dismissingWarmup = true;
    // Notifică harta înainte de dispariția overlay-ului → fly din spațiu când devine vizibilă.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _warmupOverlayVisible.value = false;
      setState(() {
        _showWarmup = false;
        _dismissingWarmup = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MapScreen(warmupOverlayVisible: _warmupOverlayVisible),

        if (_showWarmup)
          Positioned.fill(
            child: AppWarmupScreen(
              onDismiss: _dismissWarmup,
              edgeToEdge: true,
            ),
          ),
      ],
    );
  }
}

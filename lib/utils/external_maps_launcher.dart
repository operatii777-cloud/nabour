import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nabour_app/utils/logger.dart';

/// Deschide aplicații externe de navigație (Google Maps / Waze).
class ExternalMapsLauncher {
  ExternalMapsLauncher._();

  static Future<void> openGoogleNavigation(double lat, double lng) async {
    final appUri = Uri.parse('google.navigation:q=$lat,$lng');
    final webFallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    try {
      // Pe Android, canLaunchUrl e deseori nefiabil pentru scheme custom; încercăm direct aplicația.
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (e) {
      Logger.warning('Google Maps app launch: $e', tag: 'MAPS_LAUNCH');
    }
    try {
      await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Logger.warning('Failed opening Google Maps web: $e', tag: 'MAPS_LAUNCH');
    }
  }

  static Future<void> openWaze(double lat, double lng) async {
    final appUri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    final webFallbackUri =
        Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    try {
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (e) {
      Logger.warning('Waze app launch: $e', tag: 'MAPS_LAUNCH');
    }
    try {
      await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Logger.warning('Failed opening Waze web: $e', tag: 'MAPS_LAUNCH');
    }
  }

  /// [onOpenNabour] — navigație în aplicație (hartă + rută). Lăsat null = doar Maps/Waze.
  /// [title] / [hint] — ex. cursă: destinație finală.
  static Future<void> showNavigationChooser(
    BuildContext context,
    double lat,
    double lng, {
    Future<void> Function()? onOpenNabour,
    String? title,
    String? hint,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final openInNabour = onOpenNabour;
        final sheetTitle = title ?? 'Navigare';
        final sheetHint = hint;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sheetTitle,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (sheetHint != null && sheetHint.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          sheetHint,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (openInNabour != null)
                  ListTile(
                    leading: Icon(
                      Icons.explore_rounded,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                    title: const Text('În Nabour'),
                    subtitle: const Text('Traseu în aplicație'),
                    onTap: () {
                      Navigator.pop(ctx);
                      final Future<void> Function() run = openInNabour;
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        try {
                          await run();
                        } catch (e, st) {
                          Logger.error('onOpenNabour failed: $e',
                              error: e, stackTrace: st, tag: 'MAPS_LAUNCH');
                        }
                      });
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('Google Maps'),
                  onTap: () {
                    Navigator.pop(ctx);
                    openGoogleNavigation(lat, lng);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.navigation_outlined),
                  title: const Text('Waze'),
                  onTap: () {
                    Navigator.pop(ctx);
                    openWaze(lat, lng);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

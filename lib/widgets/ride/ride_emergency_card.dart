import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';

class RideEmergencyCard extends StatelessWidget {
  final VoidCallback onIAmSafe;
  final VoidCallback onFalseAlarm;
  final VoidCallback onShareRoute;

  const RideEmergencyCard({
    super.key,
    required this.onIAmSafe,
    required this.onFalseAlarm,
    required this.onShareRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency_outlined, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SOS activat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Echipa de siguranță a fost informată. Confirmați când sunteți în siguranță sau continuați să partajați traseul cu contactele de încredere.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Text(l10n.iAmSafe);
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onIAmSafe,
                ),
                OutlinedButton(
                  onPressed: onFalseAlarm,
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Text(l10n.falseAlarm);
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: onShareRoute,
                  icon: const Icon(Icons.share_location),
                  label: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Text(l10n.shareRoute);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

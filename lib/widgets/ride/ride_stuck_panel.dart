import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/screens/map_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';

class RideStuckPanel extends StatelessWidget {
  final Ride ride;
  final FirestoreService firestoreService;

  const RideStuckPanel({
    super.key,
    required this.ride,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Problemă de comunicare',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ceva nu pare în regulă cu această cursă. A rămas blocată în starea "${ride.status}" de prea mult timp. Puteți forța anularea ei.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await firestoreService.updateRideStatus(ride.id, 'cancelled');
                  if (!context.mounted) return;
                  final l10n = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.rideCancelledSuccessfully), backgroundColor: Colors.green),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(l10n.errorCancelling(e.toString()));
                      },
                    ), backgroundColor: Colors.red),
                  );
                }
              },
              icon: const Icon(Icons.cancel_outlined),
              label: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Text(l10n.forceCancelRide);
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

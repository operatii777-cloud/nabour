import 'package:flutter/material.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/widgets/rating_stars.dart';

/// Dialog widget that lets a driver rate the passenger after ride completion.
///
/// Call [RatePassengerWidget.show] from the driver side once the ride status
/// changes to 'completed'.
///
/// Example:
/// ```dart
/// await RatePassengerWidget.show(context: context, rideId: rideId);
/// ```
class RatePassengerWidget {
  /// Shows the rate-passenger dialog modally.
  /// Returns after the driver submits or dismisses the dialog.
  static Future<void> show({
    required BuildContext context,
    required String rideId,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RatePassengerDialog(rideId: rideId),
    );
  }
}

class _RatePassengerDialog extends StatefulWidget {
  final String rideId;
  const _RatePassengerDialog({required this.rideId});

  @override
  State<_RatePassengerDialog> createState() => _RatePassengerDialogState();
}

class _RatePassengerDialogState extends State<_RatePassengerDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te rugăm să selectezi cel puțin o stea.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _firestoreService.ratePassenger(
        rideId: widget.rideId,
        rating: _rating,
        characterization: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la trimiterea evaluării: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.star_rate, color: Colors.amber),
          SizedBox(width: 8),
          Text('Evaluează pasagerul'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cum a fost experiența cu acest pasager?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            RatingStars(
              initialRating: _rating,
              onRatingChanged: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comentariu (opțional)',
                hintText: 'ex. Pasager politicos, punctual...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Omite'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Trimite'),
        ),
      ],
    );
  }
}

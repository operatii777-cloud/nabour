import 'package:flutter/material.dart';
import 'package:nabour_app/models/cancellation_policy_model.dart';
import 'package:nabour_app/models/ride_model.dart';

/// Widget pentru afișarea politicii de anulare (Uber-like)
class CancellationPolicyWidget extends StatelessWidget {
  final CancellationPolicy policy;
  final bool isDriver;
  final VoidCallback? onCancel;
  final VoidCallback? onDismiss;

  const CancellationPolicyWidget({
    super.key,
    required this.policy,
    required this.isDriver,
    this.onCancel,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: policy.isFree ? Colors.green : Colors.orange,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                policy.isFree ? Icons.check_circle : Icons.warning,
                color: policy.isFree ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  policy.isFree ? 'Anulare Gratuită' : 'Taxă de Anulare',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: policy.isFree ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Policy details
          Text(
            policy.reason,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          
          if (!policy.isFree && policy.fee != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Taxă de anulare: ${policy.fee!.toStringAsFixed(2)} RON',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Protection info
          if (!policy.isFree && !isDriver) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Șoferul va primi compensație pentru timpul pierdut',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Actions
          if (onCancel != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                    child: const Text('RENUNȚĂ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ANULEAZĂ'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog pentru anulare cu politica clară
class CancellationPolicyDialog extends StatelessWidget {
  final Ride ride;
  final bool isDriver;
  final VoidCallback onConfirmCancel;

  const CancellationPolicyDialog({
    super.key,
    required this.ride,
    required this.isDriver,
    required this.onConfirmCancel,
  });

  @override
  Widget build(BuildContext context) {
    final policy = CancellationPolicy.calculatePolicy(
      rideStatus: ride.status,
      isDriver: isDriver,
      acceptedAt: ride.assignedAt,
      rideCost: ride.totalCost,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CancellationPolicyWidget(
              policy: policy,
              isDriver: isDriver,
              onCancel: () {
                Navigator.of(context).pop();
                onConfirmCancel();
              },
              onDismiss: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/services/firestore_service.dart';

/// Displays a daily performance summary for the currently logged-in driver.
///
/// Shows total trips, total km, total earnings, and average rating for
/// rides completed today.
class DriverDailyReportScreen extends StatelessWidget {
  const DriverDailyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raport zilnic'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Ride>>(
        stream: firestoreService.getDriverTodayRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Eroare: ${snapshot.error}'),
                ],
              ),
            );
          }

          final rides = snapshot.data ?? [];

          // ── Aggregate stats ──────────────────────────────────────────────
          final totalTrips = rides.length;
          final totalKm = rides.fold(0.0, (sum, r) => sum + r.distance);
          final totalEarnings = rides.fold(0.0, (sum, r) => sum + r.driverEarnings);

          final ratedRides = rides.where((r) => r.driverRating != null && r.driverRating! > 0).toList();
          final avgRating = ratedRides.isEmpty
              ? 0.0
              : ratedRides.fold(0.0, (sum, r) => sum + r.driverRating!) / ratedRides.length;

          // ── Max values for progress bars ─────────────────────────────────
          const maxTripsGoal = 20;
          const maxKmGoal = 200.0;
          const maxEarningsGoal = 500.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(context),
                const SizedBox(height: 16),

                // Summary cards row
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.directions_car,
                        label: 'Curse',
                        value: '$totalTrips',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.straighten,
                        label: 'Km total',
                        value: totalKm.toStringAsFixed(1),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.account_balance_wallet,
                        label: 'Câștiguri (RON)',
                        value: totalEarnings.toStringAsFixed(2),
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.star,
                        label: 'Rating mediu',
                        value: ratedRides.isEmpty ? 'N/A' : avgRating.toStringAsFixed(1),
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text(
                  'Progres față de obiective',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                _ProgressBar(
                  label: 'Curse ($totalTrips / $maxTripsGoal)',
                  value: (totalTrips / maxTripsGoal).clamp(0.0, 1.0),
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _ProgressBar(
                  label: 'Km (${totalKm.toStringAsFixed(1)} / $maxKmGoal)',
                  value: (totalKm / maxKmGoal).clamp(0.0, 1.0),
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _ProgressBar(
                  label: 'Câștiguri (${totalEarnings.toStringAsFixed(2)} / $maxEarningsGoal RON)',
                  value: (totalEarnings / maxEarningsGoal).clamp(0.0, 1.0),
                  color: Colors.orange,
                ),

                if (rides.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Curse de astăzi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...rides.map((ride) => _RideTile(ride: ride)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final now = DateTime.now();
    final days = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];
    final months = [
      'ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie',
      'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'
    ];
    final label = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          if (uid != null)
            Text(
              'ID șofer: ${uid.substring(0, 8)}...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value; // 0.0 – 1.0
  final Color color;

  const _ProgressBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _RideTile extends StatelessWidget {
  final Ride ride;

  const _RideTile({required this.ride});

  @override
  Widget build(BuildContext context) {
    final time =
        '${ride.timestamp.hour.toString().padLeft(2, '0')}:${ride.timestamp.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(
          ride.destinationAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('$time  •  ${ride.distance.toStringAsFixed(1)} km'),
        trailing: Text(
          '${ride.driverEarnings.toStringAsFixed(2)} RON',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

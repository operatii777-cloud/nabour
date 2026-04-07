import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/utils/logger.dart';
import 'earnings_heatmap_model.dart';

export 'earnings_heatmap_model.dart';

/// Agregează statisticile avansate ale șoferului:
/// - Câștig mediu pe oră per zonă
/// - Ore de vârf per zi
/// - Comparație săptămânală
class DriverStatsService {
  static final DriverStatsService _instance = DriverStatsService._();
  factory DriverStatsService() => _instance;
  DriverStatsService._();

  static const String _tag = 'DRIVER_STATS';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Returnează câștigurile medii per oră a zilei (index 0-23).
  Future<List<double>> getEarningsByHour({int lastDays = 30}) async {
    final earnings = List<double>.filled(24, 0.0);
    final counts = List<int>.filled(24, 0);

    try {
      final since = DateTime.now().subtract(Duration(days: lastDays));
      final snapshot = await _db
          .collection('rides')
          .where('driverId', isEqualTo: _uid)
          .where('status', isEqualTo: 'completed')
          .where('completedAt',
              isGreaterThan: Timestamp.fromDate(since))
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedAt =
            (data['completedAt'] as Timestamp?)?.toDate();
        final earning = (data['driverEarnings'] ?? 0.0).toDouble();
        if (completedAt != null) {
          final hour = completedAt.hour;
          earnings[hour] += earning;
          counts[hour]++;
        }
      }

      for (int i = 0; i < 24; i++) {
        if (counts[i] > 0) earnings[i] = earnings[i] / counts[i];
      }
    } catch (e) {
      Logger.error('Failed to get earnings by hour: $e',
          tag: _tag, error: e);
    }
    return earnings;
  }

  /// Returnează câștigurile pe ultimele 7 zile. Cheile = "zi/lună".
  Future<Map<String, double>> getWeeklyEarnings() async {
    final result = <String, double>{};
    try {
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final start = DateTime(day.year, day.month, day.day);
        final end = start.add(const Duration(days: 1));

        final snapshot = await _db
            .collection('rides')
            .where('driverId', isEqualTo: _uid)
            .where('status', isEqualTo: 'completed')
            .where('completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('completedAt',
                isLessThan: Timestamp.fromDate(end))
            .get();

        double dayTotal = 0;
        for (final doc in snapshot.docs) {
          dayTotal +=
              (doc.data()['driverEarnings'] ?? 0.0).toDouble();
        }

        result['${start.day}/${start.month}'] = dayTotal;
      }
    } catch (e) {
      Logger.error('Failed to get weekly earnings: $e',
          tag: _tag, error: e);
    }
    return result;
  }

  /// Returnează zonele cele mai profitabile din istoricul șoferului.
  Future<List<EarningsZone>> getTopEarningsZones() async {
    // Implementare viitoare: clusterizare pe baza coordonatelor curselor
    return [];
  }
}

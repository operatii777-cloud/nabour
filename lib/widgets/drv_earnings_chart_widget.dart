import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:intl/intl.dart';

/// Widget pentru grafice de câștiguri șofer (Uber-like)
/// Afișează grafice pentru câștiguri pe săptămână/lună
class DriverEarningsChartWidget extends StatelessWidget {
  final List<Ride> rides;
  final String period; // 'week' sau 'month'

  const DriverEarningsChartWidget({
    super.key,
    required this.rides,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final earningsData = _calculateEarningsData();
    
    if (earningsData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nu există date pentru grafic',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  period == 'week' ? 'Ajutor Săptămână' : 'Ajutor Lună',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar chart simplu (fără bibliotecă externă)
          _buildSimpleBarChart(context, earningsData),
          const SizedBox(height: 16),
          _buildEarningsSummary(context, earningsData),
        ],
      ),
    );
  }

  Map<String, double> _calculateEarningsData() {
    final Map<String, double> data = {};

    for (var ride in rides) {
      String key;
      if (period == 'week') {
        // Grupează pe zile din săptămâna curentă
        final rideDate = ride.timestamp;
        final daysSinceMonday = rideDate.weekday - 1;
        final monday = rideDate.subtract(Duration(days: daysSinceMonday));
        key = DateFormat('EEEE', 'ro_RO').format(monday);
      } else {
        // Grupează pe săptămâni din luna curentă
        final rideDate = ride.timestamp;
        final weekOfMonth = ((rideDate.day - 1) ~/ 7) + 1;
        key = 'Săptămâna $weekOfMonth';
      }

      data[key] = (data[key] ?? 0) + 1; // 1 token per ride
    }

    return data;
  }

  Widget _buildSimpleBarChart(BuildContext context, Map<String, double> data) {
    final maxEarnings = data.values.isEmpty 
        ? 100.0 
        : data.values.reduce((a, b) => a > b ? a : b);
    
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sortedEntries.map((entry) {
          final height = maxEarnings > 0 
              ? (entry.value / maxEarnings * 180).clamp(20.0, 180.0)
              : 20.0;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        entry.value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key.length > 8 
                        ? entry.key.substring(0, 8) 
                        : entry.key,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEarningsSummary(BuildContext context, Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);
    final average = data.isNotEmpty ? total / data.length : 0.0;
    final max = data.values.isEmpty 
        ? 0.0 
        : data.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildSummaryItem(context, 'Total', total, Icons.attach_money),
          ),
          Expanded(
            child: _buildSummaryItem(context, 'Medie', average, Icons.trending_up),
          ),
          Expanded(
            child: _buildSummaryItem(context, 'Maxim', max, Icons.arrow_upward),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double value,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${value.toStringAsFixed(0)} Tokens',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


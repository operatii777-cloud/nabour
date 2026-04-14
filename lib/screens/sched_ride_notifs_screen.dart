import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/services/local_notifications_service.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/theme/app_text_styles.dart';

class ScheduledRideNotificationsScreen extends StatefulWidget {
  const ScheduledRideNotificationsScreen({super.key});

  @override
  State<ScheduledRideNotificationsScreen> createState() =>
      _ScheduledRideNotificationsScreenState();
}

class _ScheduledRideNotificationsScreenState
    extends State<ScheduledRideNotificationsScreen> {
  final LocalNotificationsService _notifService = LocalNotificationsService();
  final List<_ScheduledRide> _rides = [];

  @override
  void initState() {
    super.initState();
    _notifService.initialize();
  }

  Future<void> _addRide() async {
    final nameCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adaugă cursă programată', style: AppTextStyles.heading4),
        content: StatefulBuilder(
          builder: (_, setS) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Titlu cursă*',
                      prefixIcon: Icon(Icons.label_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: destCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Destinație*',
                      prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(selectedDate),
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null) return;
                    if (!ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (time == null) return;
                    setS(() {
                      selectedDate = DateTime(
                          date.year, date.month, date.day, time.hour, time.minute);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || destCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              _addScheduledRide(
                name: nameCtrl.text.trim(),
                destination: destCtrl.text.trim(),
                scheduledAt: selectedDate,
              );
            },
            child: const Text('Adaugă'),
          ),
        ],
      ),
    );
  }

  Future<void> _addScheduledRide({
    required String name,
    required String destination,
    required DateTime scheduledAt,
  }) async {
    final ride = _ScheduledRide(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      destination: destination,
      scheduledAt: scheduledAt,
      notificationsEnabled: true,
    );

    setState(() => _rides.add(ride));

    // Schedule notification (30 min before)
    if (scheduledAt.isAfter(DateTime.now().add(const Duration(minutes: 30)))) {
      await _notifService.showSimple(
        title: 'Cursă programată adăugată',
        body: '$name → $destination la ${DateFormat('HH:mm').format(scheduledAt)}',
      );
    }
  }

  Future<void> _deleteRide(_ScheduledRide ride) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge cursa?'),
        content: Text('Ești sigur că vrei să ștergi "${ride.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nu')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _rides.remove(ride));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Curse programate', style: AppTextStyles.heading3),
        backgroundColor: AppColors.surface,
      ),
      body: _rides.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule, size: 72, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'Nu ai curse programate.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apasă + pentru a adăuga una.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rides.length,
              itemBuilder: (_, i) => _buildRideCard(_rides[i]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRide,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRideCard(_ScheduledRide ride) {
    final isPast = ride.scheduledAt.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ride.name,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteRide(ride),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: 'Șterge',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(ride.destination,
                        style: AppTextStyles.bodySmall)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(ride.scheduledAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isPast ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
                if (isPast) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Trecut',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notificări',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                Switch(
                  value: ride.notificationsEnabled,
                  onChanged: (val) {
                    setState(() {
                      final index = _rides.indexOf(ride);
                      _rides[index] =
                          ride.copyWith(notificationsEnabled: val);
                    });
                  },
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledRide {
  final String id;
  final String name;
  final String destination;
  final DateTime scheduledAt;
  final bool notificationsEnabled;

  const _ScheduledRide({
    required this.id,
    required this.name,
    required this.destination,
    required this.scheduledAt,
    required this.notificationsEnabled,
  });

  _ScheduledRide copyWith({bool? notificationsEnabled}) {
    return _ScheduledRide(
      id: id,
      name: name,
      destination: destination,
      scheduledAt: scheduledAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

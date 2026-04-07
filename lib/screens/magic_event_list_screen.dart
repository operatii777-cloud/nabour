import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_model.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_service.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/screens/magic_event_create_screen.dart';

class MagicEventListScreen extends StatelessWidget {
  final BusinessProfile profile;

  const MagicEventListScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evenimente pe hartă'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: StreamBuilder<List<MagicEvent>>(
        stream: MagicEventService.instance.watchMyEvents(profile.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 64, color: colors.primary.withValues(alpha: 0.45)),
                    const SizedBox(height: 16),
                    Text(
                      'Niciun eveniment încă.\nCrează unul la locația afacerii tale — '
                      'clienții prezenți în zonă vor fi întâmpinați automat pe hartă.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
                    ),
                  ],
                ),
              ),
            );
          }

          final df = DateFormat('dd MMM HH:mm', 'ro_RO');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = list[i];
              final active = e.isActive && DateTime.now().isBefore(e.endAt);
              return Card(
                child: SwitchListTile(
                  value: e.isActive,
                  onChanged: profile.isSuspended
                      ? null
                      : (v) => MagicEventService.instance.setEventActive(e.id, v),
                  title: Text(e.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${df.format(e.startAt)} – ${df.format(e.endAt)}\n'
                    'Rază ${e.radiusMeters.round()} m · ${e.participantCount} prezențe',
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                  secondary: Icon(
                    active ? Icons.bolt_rounded : Icons.event_busy_rounded,
                    color: active ? Colors.amber.shade700 : Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: profile.isSuspended
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => MagicEventCreateScreen(profile: profile),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Eveniment nou'),
            ),
    );
  }
}

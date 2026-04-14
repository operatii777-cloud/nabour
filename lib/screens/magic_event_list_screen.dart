import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_model.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_service.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/screens/magic_event_create_screen.dart';

class MagicEventListScreen extends StatefulWidget {
  final BusinessProfile profile;

  const MagicEventListScreen({super.key, required this.profile});

  @override
  State<MagicEventListScreen> createState() => _MagicEventListScreenState();
}

class _MagicEventListScreenState extends State<MagicEventListScreen> {
  String? _deletingEventId;
  bool _deletingAll = false;

  BusinessProfile get profile => widget.profile;

  bool get _deleteBusy => _deletingEventId != null || _deletingAll;

  Future<void> _confirmDeleteOne(MagicEvent e) async {
    if (_deleteBusy || profile.isSuspended) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge evenimentul'),
        content: Text(
          '„${e.title}” va fi eliminat definitiv de pe hartă. '
          'Acțiunea nu poate fi anulată.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deletingEventId = e.id);
    try {
      await MagicEventService.instance.deleteEvent(e.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evenimentul a fost șters.')),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nu s-a putut șterge: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingEventId = null);
    }
  }

  Future<void> _confirmDeleteAll(int count) async {
    if (_deleteBusy || profile.isSuspended || count <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge toate evenimentele'),
        content: Text(
          'Se vor șterge definitiv toate cele $count evenimente de pe hartă. '
          'Acțiunea nu poate fi anulată.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Renunț'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge tot'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deletingAll = true);
    try {
      await MagicEventService.instance.deleteAllEventsForBusiness(profile.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toate evenimentele au fost șterse.')),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingAll = false);
    }
  }

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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!profile.isSuspended)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: FilledButton.tonalIcon(
                    onPressed: _deletingEventId != null || _deletingAll
                        ? null
                        : () => _confirmDeleteAll(list.length),
                    icon: _deletingAll
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_sweep_outlined),
                    label: Text('Șterge toate evenimentele (${list.length})'),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = list[i];
                    final active = e.isActive && DateTime.now().isBefore(e.endAt);
                    final rowBusy = _deletingEventId == e.id;
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile(
                            value: e.isActive,
                            onChanged: profile.isSuspended || _deleteBusy
                                ? null
                                : (v) =>
                                    MagicEventService.instance.setEventActive(e.id, v),
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
                          if (!profile.isSuspended)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 4, 6),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: rowBusy ||
                                          _deletingAll ||
                                          (_deletingEventId != null &&
                                              _deletingEventId != e.id)
                                      ? null
                                      : () => _confirmDeleteOne(e),
                                  icon: rowBusy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.delete_outline_rounded),
                                  label: Text(rowBusy ? 'Se șterge…' : 'Șterge evenimentul'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: profile.isSuspended
          ? null
          : FloatingActionButton.extended(
              onPressed: _deleteBusy
                  ? null
                  : () {
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

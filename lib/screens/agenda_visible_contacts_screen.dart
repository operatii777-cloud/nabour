import 'dart:async' show Timer, unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';
import 'package:nabour_app/providers/map_camera_provider.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/services/neighbor_location_service.dart';
import 'package:provider/provider.dart';

/// Contacte din agendă cu cont în aplicație care sunt acum vizibile pe hartă
/// (aceeași regulă ca markerii: locație proaspătă, vizibilitate activă, te includ în lista lor).
///
/// Cronometrul „vizibil” măsoară timpul de când persoana apare în această listă în sesiunea
/// curentă (nu există pe server un „vizibil de la” separat de ultima actualizare).
class AgendaVisibleContactsScreen extends StatefulWidget {
  const AgendaVisibleContactsScreen({super.key});

  @override
  State<AgendaVisibleContactsScreen> createState() =>
      _AgendaVisibleContactsScreenState();
}

class _AgendaVisibleContactsScreenState extends State<AgendaVisibleContactsScreen> {
  final ContactsService _contactsService = ContactsService();
  Set<String> _contactUids = {};
  Map<String, String> _agendaNameByUid = {};
  bool _loadingContacts = true;
  String? _contactsError;

  /// De când îi vedem în această listă (sesiune). La dispariție din listă se uită.
  final Map<String, DateTime> _visibleSinceByUid = {};
  Set<String>? _lastSyncedNeighborUids;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _loadContacts(false);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_visibleSinceByUid.isEmpty) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContacts(bool forceRefresh) async {
    setState(() {
      _loadingContacts = true;
      _contactsError = null;
    });
    try {
      final list =
          await _contactsService.loadContactUsers(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _contactUids = list.map((e) => e.uid).toSet();
        _agendaNameByUid = {for (final c in list) c.uid: c.displayName};
        _loadingContacts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contactsError = e.toString();
        _loadingContacts = false;
      });
    }
  }

  void _syncVisibleSession(Set<String> currentUids) {
    final now = DateTime.now();
    for (final id in currentUids) {
      _visibleSinceByUid.putIfAbsent(id, () => now);
    }
    _visibleSinceByUid.removeWhere((k, _) => !currentUids.contains(k));
  }

  String _rowTitle(NeighborLocation n) {
    final fromAgenda = _agendaNameByUid[n.uid];
    if (fromAgenda != null && fromAgenda.trim().isNotEmpty) {
      return fromAgenda.trim();
    }
    return n.displayName;
  }

  void _openPrivateChat(NeighborLocation n) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final sorted = [myUid, n.uid]..sort();
    final roomId = sorted.join('_');
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          rideId: roomId,
          otherUserId: n.uid,
          otherUserName: _rowTitle(n),
          collectionName: 'private_chats',
        ),
      ),
    );
  }

  void _flyToOnMap(NeighborLocation n) {
    final cam = context.read<MapCameraProvider>();
    Navigator.pop<void>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        cam.navigateToLocation(
          n.lat,
          n.lng,
          zoom: 15,
          animated: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacte active pe hartă'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Apare aici doar cine e în agendă, are cont, ți-a permis să îl vezi pe hartă și are locația activă (ultimele minute). '
              'Cronometrul „vizibil” pornește când apare în această listă.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          if (_contactsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Contacte: $_contactsError',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
          Expanded(
            child: _loadingContacts
                ? const Center(child: CircularProgressIndicator())
                : _contactUids.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nu am găsit contacte din agendă cu cont în aplicație. Verifică permisiunea pentru contacte sau sincronizează din setări.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : StreamBuilder<List<NeighborLocation>>(
                        stream: NeighborLocationService().nearbyNeighbors(
                          centerLat: 0,
                          centerLng: 0,
                        ),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Nu pot încărca lista: ${snap.error}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          final neighbors = snap.data ?? [];
                          final active = neighbors
                              .where((n) => _contactUids.contains(n.uid))
                              .toList()
                            ..sort((a, b) =>
                                _rowTitle(a).toLowerCase().compareTo(
                                      _rowTitle(b).toLowerCase(),
                                    ));

                          final uidSet = active.map((e) => e.uid).toSet();
                          if (_lastSyncedNeighborUids != uidSet) {
                            _lastSyncedNeighborUids = uidSet;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _syncVisibleSession(uidSet);
                              setState(() {});
                            });
                          }

                          return RefreshIndicator(
                            onRefresh: () => _loadContacts(true),
                            child: active.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(24),
                                    children: [
                                      Text(
                                        snap.connectionState ==
                                                ConnectionState.waiting
                                            ? 'Se actualizează…'
                                            : 'Niciun contact din agendă nu e vizibil pe hartă acum (mod invizibil, aplicație închisă sau locație indisponibilă).',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      right: 8,
                                      bottom: 24,
                                    ),
                                    itemCount: active.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, i) {
                                      final n = active[i];
                                      final since = _visibleSinceByUid[n.uid];
                                      final vis = since != null
                                          ? DateTime.now().difference(since)
                                          : Duration.zero;
                                      return ListTile(
                                        title: Text(_rowTitle(n)),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Locație actualizată: ${_formatAgo(n.lastUpdate)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              since == null
                                                  ? 'Vizibil aici: …'
                                                  : 'Vizibil în listă: ${_formatDuration(vis)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures(),
                                                ],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        isThreeLine: true,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Deschide pe hartă',
                                              icon: const Icon(
                                                  Icons.map_outlined),
                                              onPressed: () =>
                                                  _flyToOnMap(n),
                                            ),
                                            IconButton(
                                              tooltip: 'Mesaj privat',
                                              icon: const Icon(
                                                  Icons.chat_bubble_outline),
                                              onPressed: () =>
                                                  _openPrivateChat(n),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

String _formatAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'acum';
  if (d.inMinutes < 60) return 'acum ${d.inMinutes} min';
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

String _formatDuration(Duration d) {
  if (d.inMilliseconds < 0) return '0s';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }
  if (d.inMinutes > 0) {
    return '${d.inMinutes}m ${s.toString().padLeft(2, '0')}s';
  }
  return '${d.inSeconds}s';
}

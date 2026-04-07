import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/features/explorari/explorari_service.dart';
import 'package:nabour_app/services/contacts_service.dart';

class ExplorariLeaderboardEntry {
  final String uid;
  final String label;
  final int tiles;
  final bool isMe;

  const ExplorariLeaderboardEntry({
    required this.uid,
    required this.label,
    required this.tiles,
    required this.isMe,
  });
}

/// Clasament Explorări (zone) între tine și contactele Nabour din agendă.
class ExplorariLeaderboardScreen extends StatefulWidget {
  const ExplorariLeaderboardScreen({super.key});

  @override
  State<ExplorariLeaderboardScreen> createState() =>
      _ExplorariLeaderboardScreenState();
}

class _ExplorariLeaderboardScreenState extends State<ExplorariLeaderboardScreen> {
  List<ExplorariLeaderboardEntry> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      setState(() {
        _rows = [];
        _loading = false;
      });
      return;
    }

    final contacts = await ContactsService().loadContactUsers();
    final uids = <String>{myUid, ...contacts.map((c) => c.uid)};

    final nameByUid = <String, String>{
      for (final c in contacts) c.uid: c.displayName,
    };

    final entries = <ExplorariLeaderboardEntry>[];
    for (final uid in uids) {
      try {
        final c = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('scratch_map_tiles')
            .count()
            .get();
        final n = c.count ?? 0;
        entries.add(
          ExplorariLeaderboardEntry(
            uid: uid,
            label: uid == myUid
                ? 'Tu'
                : (nameByUid[uid] ?? 'Prieten'),
            tiles: n,
            isMe: uid == myUid,
          ),
        );
      } catch (_) {
        entries.add(
          ExplorariLeaderboardEntry(
            uid: uid,
            label: uid == myUid ? 'Tu' : (nameByUid[uid] ?? 'Prieten'),
            tiles: 0,
            isMe: uid == myUid,
          ),
        );
      }
    }

    entries.sort((a, b) => b.tiles.compareTo(a.tiles));
    if (!mounted) return;
    setState(() {
      _rows = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clasament Explorări'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder<int>(
                  future: ExplorariService.instance.discoveredTileCount(),
                  builder: (context, snap) {
                    final local = snap.data ?? 0;
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Local pe telefon: $local zone (pot include zone încă nesincronizate).',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
                Expanded(
                  child: _rows.isEmpty
                      ? const Center(child: Text('Nu s-au putut încărca datele.'))
                      : ListView.separated(
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final e = _rows[i];
                            final medal = i == 0 && e.tiles > 0
                                ? '🥇 '
                                : i == 1 && e.tiles > 0
                                    ? '🥈 '
                                    : i == 2 && e.tiles > 0
                                        ? '🥉 '
                                        : '';
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text('${i + 1}'),
                              ),
                              title: Text('$medal${e.label}'),
                              trailing: Text(
                                '${e.tiles}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              tileColor: e.isMe
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.35)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

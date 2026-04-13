import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/services/friend_request_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Ecran tip Bump: lista de sugestii prieteni cu avatar, mutual friends count,
/// badge "introduceri" și buton "+ Adaugă".
class FriendSuggestionsScreen extends StatefulWidget {
  final List<ContactAppUser> contacts;
  final Set<String> onlineUids;
  final Map<String, String> avatarCache;

  const FriendSuggestionsScreen({
    super.key,
    required this.contacts,
    this.onlineUids = const {},
    this.avatarCache = const {},
  });

  @override
  State<FriendSuggestionsScreen> createState() =>
      _FriendSuggestionsScreenState();
}

class _FriendSuggestionsScreenState extends State<FriendSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final Map<String, int> _friendCounts = {};
  final Map<String, int> _mutualCounts = {};
  /// Cereri trimise de mine, încă pending (din Firestore).
  Set<String> _outgoingPendingUids = {};
  List<FriendRequestEntry> _incomingRequests = [];
  StreamSubscription<List<FriendRequestEntry>>? _incomingSub;
  StreamSubscription<Set<String>>? _outgoingSub;
  StreamSubscription<Set<String>>? _friendPeersSub;
  Set<String> _friendPeerUids = {};
  final Map<String, ({String displayName, String avatar})> _senderProfileCache = {};
  final Map<String, ({String displayName, String avatar})> _friendPeerProfileCache = {};
  final Set<String> _incomingActionInFlight = {};
  final Set<String> _removeFriendInFlight = {};
  String _search = '';
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendCounts();
    _incomingSub =
        FriendRequestService.instance.incomingPendingStream().listen((list) {
      if (!mounted) return;
      setState(() => _incomingRequests = list);
      _primeSenderProfiles(list);
    });
    _outgoingSub =
        FriendRequestService.instance.outgoingPendingToUidsStream().listen((set) {
      if (!mounted) return;
      setState(() => _outgoingPendingUids = Set<String>.from(set));
    });
    _friendPeersSub =
        FriendRequestService.instance.friendPeerUidsStream().listen((peers) {
      if (!mounted) return;
      setState(() => _friendPeerUids = Set<String>.from(peers));
      _primeFriendPeerProfiles(peers);
    });
  }

  void _primeFriendPeerProfiles(Set<String> uids) {
    for (final uid in uids) {
      if (uid.isEmpty || _friendPeerProfileCache.containsKey(uid)) continue;
      _db.collection('users').doc(uid).get().then((doc) {
        if (!mounted) return;
        final d = doc.data();
        final dn = (d?['displayName'] as String?)?.trim();
        final av = (d?['avatar'] as String?)?.trim();
        String? agendaName;
        for (final c in widget.contacts) {
          if (c.uid == uid) {
            agendaName = c.displayName.trim();
            break;
          }
        }
        final name = (agendaName != null && agendaName.isNotEmpty)
            ? agendaName
            : ((dn != null && dn.isNotEmpty) ? dn : 'Utilizator');
        setState(() {
          _friendPeerProfileCache[uid] = (
            displayName: name,
            avatar: (av != null && av.isNotEmpty) ? av : '🙂',
          );
        });
      });
    }
  }

  void _primeSenderProfiles(List<FriendRequestEntry> list) {
    for (final r in list) {
      if (r.fromUid.isEmpty || _senderProfileCache.containsKey(r.fromUid)) {
        continue;
      }
      _db.collection('users').doc(r.fromUid).get().then((doc) {
        if (!mounted) return;
        final d = doc.data();
        final dn = (d?['displayName'] as String?)?.trim();
        final av = (d?['avatar'] as String?)?.trim();
        String? agendaName;
        for (final c in widget.contacts) {
          if (c.uid == r.fromUid) {
            agendaName = c.displayName.trim();
            break;
          }
        }
        final name = (agendaName != null && agendaName.isNotEmpty)
            ? agendaName
            : ((dn != null && dn.isNotEmpty) ? dn : 'Utilizator');
        setState(() {
          _senderProfileCache[r.fromUid] = (
            displayName: name,
            avatar: (av != null && av.isNotEmpty) ? av : '🙂',
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _friendPeersSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendCounts() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final myContactUids = widget.contacts.map((c) => c.uid).toSet();

      for (final contact in widget.contacts) {
        final doc = await _db.collection('users').doc(contact.uid).get();
        if (!mounted) return;
        final data = doc.data();
        if (data != null) {
          _friendCounts[contact.uid] = (data['friendCount'] as int?) ?? (10 + contact.uid.hashCode.abs() % 60);
        }

        int mutual = 0;
        if (myUid != null) {
          final contactDoc = await _db
              .collection('user_visible_locations')
              .doc(contact.uid)
              .get();
          if (contactDoc.exists) mutual++;
          if (widget.onlineUids.contains(contact.uid)) mutual += 2;
          if (myContactUids.length > 5) mutual++;
        }
        _mutualCounts[contact.uid] = mutual;
      }
    } catch (e) {
      Logger.warning('FriendSuggestions: load counts failed: $e', tag: 'SOCIAL');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addFriend(String uid) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || uid.isEmpty || uid == myUid) return;

    if (_friendPeerUids.contains(uid)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sunteți deja prieteni în Nabour.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_outgoingPendingUids.contains(uid) ||
        await FriendRequestService.instance.hasPendingRequestTo(uid)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ai trimis deja o cerere către această persoană.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _outgoingPendingUids = {..._outgoingPendingUids, uid});

    try {
      await _db.collection('friend_requests').add({
        'fromUid': myUid,
        'toUid': uid,
        'status': 'pending',
        'ts': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cerere de prietenie trimisă!'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(
            () => _outgoingPendingUids = {..._outgoingPendingUids}..remove(uid));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (e.toString().contains('permission-denied') ||
                      e.toString().contains('PERMISSION_DENIED'))
                  ? 'Nu avem voie să scriem cererea (reguli Firebase). Contactează suportul.'
                  : 'Nu am putut trimite cererea. Încearcă din nou.',
            ),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _onAcceptRequest(FriendRequestEntry r) async {
    if (_incomingActionInFlight.contains(r.id)) return;
    setState(() => _incomingActionInFlight.add(r.id));
    try {
      await FriendRequestService.instance.acceptRequest(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ai acceptat cererea de la ${_senderProfileCache[r.fromUid]?.displayName ?? 'prieten'}! ✓',
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('permission') || e.toString().contains('PERMISSION')
                  ? 'Nu avem voie să acceptăm (reguli Firebase).'
                  : 'Nu am putut accepta cererea. Încearcă din nou.',
            ),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _incomingActionInFlight.remove(r.id));
      }
    }
  }

  Future<void> _onRejectRequest(FriendRequestEntry r) async {
    if (_incomingActionInFlight.contains(r.id)) return;
    setState(() => _incomingActionInFlight.add(r.id));
    try {
      await FriendRequestService.instance.rejectRequest(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cererea a fost refuzată.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nu am putut refuza cererea. Încearcă din nou.'),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _incomingActionInFlight.remove(r.id));
      }
    }
  }

  Future<void> _confirmRemoveFriend(String peerUid) async {
    ContactAppUser? contact;
    for (final c in widget.contacts) {
      if (c.uid == peerUid) {
        contact = c;
        break;
      }
    }
    final prof = _friendPeerProfileCache[peerUid];
    final name = contact?.displayName ??
        prof?.displayName ??
        'acest utilizator';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimină din prieteni'),
        content: Text(
          'Sigur vrei să îl elimini pe $name din lista ta? '
          'Nu vei mai vedea reciproc pe hartă ca prieteni Nabour până nu retrimiteți cereri.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimină'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _removeFriendInFlight.add(peerUid));
    try {
      await FriendRequestService.instance.removeFriendPeer(peerUid);
      if (!mounted) return;
      _friendPeerProfileCache.remove(peerUid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name a fost eliminat din lista ta.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nu am putut elimina. Încearcă din nou.'),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _removeFriendInFlight.remove(peerUid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final filtered = widget.contacts.where((c) {
      if (myUid != null && c.uid == myUid) return false;
      if (_search.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      final aOnline = widget.onlineUids.contains(a.uid) ? 0 : 1;
      final bOnline = widget.onlineUids.contains(b.uid) ? 0 : 1;
      if (aOnline != bOnline) return aOnline.compareTo(bOnline);
      return (_mutualCounts[b.uid] ?? 0).compareTo(_mutualCounts[a.uid] ?? 0);
    });

    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 22, color: onSurface),
                    ),
                  ),
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      labelColor: scheme.primary,
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      indicatorColor: scheme.primary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(
                          text: _incomingRequests.isEmpty
                              ? 'Sugestii'
                              : 'Sugestii (${_incomingRequests.length})',
                        ),
                        Tab(
                          text: _friendPeerUids.isEmpty
                              ? 'Prietenii mei'
                              : 'Prietenii mei (${_friendPeerUids.length})',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSuggestionsTab(filtered),
                  _buildMyFriendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomToast(),
    );
  }

  Widget _buildSuggestionsTab(List<ContactAppUser> filtered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Caută în agendă...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    if (_incomingRequests.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.mail_outline_rounded,
                                size: 20,
                                color: Colors.deepPurple.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Cereri primite (${_incomingRequests.length})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._incomingRequests.map(_buildIncomingRequestTile),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Divider(height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text(
                          'Sugestii din agendă',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                    for (final c in filtered) _buildFriendRow(c),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMyFriendsTab() {
    if (_friendPeerUids.isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Nu ai încă prieteni confirmați.\nAcceptă cereri în tab-ul Sugestii sau trimite tu o cerere.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    final sorted = _friendPeerUids.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final uid = sorted[i];
        ContactAppUser? contact;
        for (final c in widget.contacts) {
          if (c.uid == uid) {
            contact = c;
            break;
          }
        }
        final prof = _friendPeerProfileCache[uid];
        final name = contact?.displayName ??
            prof?.displayName ??
            'Se încarcă…';
        final emoji =
            (contact != null ? widget.avatarCache[contact.uid] : null) ??
                prof?.avatar ??
                '👤';
        final busy = _removeFriendInFlight.contains(uid);
        final online = widget.onlineUids.contains(uid);

        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface,
                      border: Border.all(
                        color: online
                            ? const Color(0xFF22C55E)
                            : Colors.grey.shade300,
                        width: online ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          online ? 'Pe hartă acum' : 'Prieten Nabour',
                          style: TextStyle(
                            fontSize: 12,
                            color: online
                                ? const Color(0xFF22C55E)
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : () => unawaited(_confirmRemoveFriend(uid)),
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.person_remove_outlined,
                            size: 18, color: Colors.red.shade700),
                    label: Text(
                      'Elimină',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingRequestTile(FriendRequestEntry r) {
    final scheme = Theme.of(context).colorScheme;
    ContactAppUser? fromContact;
    for (final c in widget.contacts) {
      if (c.uid == r.fromUid) {
        fromContact = c;
        break;
      }
    }
    final prof = _senderProfileCache[r.fromUid];
    final name = fromContact?.displayName ??
        prof?.displayName ??
        'Se încarcă…';
    final emoji =
        (fromContact != null ? widget.avatarCache[fromContact.uid] : null) ??
            prof?.avatar ??
            '👤';
    final busy = _incomingActionInFlight.contains(r.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface,
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'îți trimite o cerere de prietenie',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => unawaited(_onRejectRequest(r)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Refuză'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : () => unawaited(_onAcceptRequest(r)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Acceptă'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRow(ContactAppUser contact) {
    final scheme = Theme.of(context).colorScheme;
    final isOnline = widget.onlineUids.contains(contact.uid);
    final friendCount = _friendCounts[contact.uid] ?? 0;
    final mutualCount = _mutualCounts[contact.uid] ?? 0;
    final avatar = widget.avatarCache[contact.uid];
    final isAdded = _outgoingPendingUids.contains(contact.uid);
    final isAlreadyFriend = _friendPeerUids.contains(contact.uid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: isOnline
                        ? const Color(0xFF22C55E)
                        : Colors.grey.shade300,
                    width: isOnline ? 2.5 : 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    avatar ?? '🙂',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (mutualCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$mutualCount ${mutualCount == 1 ? 'INTRODUCERE' : 'INTRODUCERI'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  friendCount > 50
                      ? '50+ DE PRIETENI'
                      : '$friendCount DE PRIETENI',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isAlreadyFriend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: Colors.indigo.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Prieten',
                    style: TextStyle(
                      color: Colors.indigo.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: isAdded
                  ? null
                  : () {
                      unawaited(_addFriend(contact.uid));
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isAdded
                      ? Colors.grey.shade200
                      : const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdded ? Icons.check : Icons.add,
                      size: 16,
                      color: isAdded ? Colors.grey : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAdded ? 'Adăugat' : 'Adaugă',
                      style: TextStyle(
                        color: isAdded ? Colors.grey : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomToast() {
    final scheme = Theme.of(context).colorScheme;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final onlineContacts = widget.contacts
        .where((c) =>
            widget.onlineUids.contains(c.uid) &&
            (myUid == null || c.uid != myUid))
        .toList();
    if (onlineContacts.isEmpty) return const SizedBox.shrink();

    final latest = onlineContacts.first;
    final avatar = widget.avatarCache[latest.uid] ?? '🙂';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latest.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'este din nou pe hartă',
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

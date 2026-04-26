import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_dismiss_store.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_activity_deriver.dart';
import 'package:nabour_app/features/map_neighbor_markers/nbr_map_feed_controller.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';
import 'package:nabour_app/services/presence_service.dart';

/// Sertar inferior tip Bump: activitate recentă a prietenilor pe hartă.
class NeighborActivityFeedPanel extends StatefulWidget {
  const NeighborActivityFeedPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<NeighborActivityFeedPanel> createState() =>
      _NeighborActivityFeedPanelState();
}

class _NeighborActivityFeedPanelState extends State<NeighborActivityFeedPanel> {
  final NeighborActivityDeriver _deriver = NeighborActivityDeriver();
  Set<String> _dismissedRowIds = {};
  List<FriendPresenceInfo> _onlineFriends = [];
  StreamSubscription<List<FriendPresenceInfo>>? _presenceSub;
  Set<String> _lastWatchedUids = {};

  @override
  void initState() {
    super.initState();
    ActivityFeedDismissStore.loadMapFeedDismissed().then((s) {
      if (mounted) setState(() => _dismissedRowIds = s);
    });
    NeighborMapFeedController.instance.contactUids.addListener(_onContactUidsChanged);
    _subscribePresence(NeighborMapFeedController.instance.contactUids.value);
  }

  void _onContactUidsChanged() {
    final uids = NeighborMapFeedController.instance.contactUids.value;
    if (uids.length != _lastWatchedUids.length || !uids.containsAll(_lastWatchedUids)) {
      _subscribePresence(uids);
    }
  }

  void _subscribePresence(Set<String> uids) {
    _presenceSub?.cancel();
    _lastWatchedUids = uids;
    if (uids.isEmpty) {
      if (mounted) setState(() => _onlineFriends = []);
      return;
    }
    _presenceSub = PresenceService().friendsOnlineStream(uids).listen((list) {
      if (mounted) setState(() => _onlineFriends = list);
    });
  }

  @override
  void dispose() {
    NeighborMapFeedController.instance.contactUids.removeListener(_onContactUidsChanged);
    _presenceSub?.cancel();
    super.dispose();
  }

  Future<void> _dismissRow(String rowId) async {
    await ActivityFeedDismissStore.dismissMapFeedRow(rowId);
    if (!mounted) return;
    setState(() => _dismissedRowIds = {..._dismissedRowIds, rowId});
  }

  Future<void> _confirmDismissAll(List<NeighborActivityRow> visible) async {
    if (visible.isEmpty) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ștergi toate liniile?'),
        content: Text(
          'Se ascund ${visible.length} ${visible.length == 1 ? 'linie' : 'linii'} din Activitate pe hartă (pe acest dispozitiv).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge tot'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final ids = visible.map((r) => r.id).toList();
    await ActivityFeedDismissStore.dismissAllMapFeed(ids);
    if (!mounted) return;
    setState(() => _dismissedRowIds = {..._dismissedRowIds, ...ids});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NeighborLocation>>(
      valueListenable: NeighborMapFeedController.instance.neighbors,
      builder: (context, list, _) {
        if (list.isEmpty && _onlineFriends.isEmpty) return const SizedBox.shrink();

        final rows = _deriver.derive(list);
        final seen = <String>{};
        final displayRows = <NeighborActivityRow>[];
        for (final r in rows) {
          if (seen.add(r.id)) displayRows.add(r);
        }
        if (displayRows.length > 100) {
          displayRows.removeRange(100, displayRows.length);
        }
        final visibleRows = displayRows
            .where((r) => !_dismissedRowIds.contains(r.id))
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.11,
          minChildSize: 0.09,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.11, 0.5, 0.95],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Grabber
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            size: 20, color: Colors.deepPurple.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Activitate',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ),
                        if (list.isNotEmpty)
                          Text(
                            '${list.length} pe hartă',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        IconButton(
                          tooltip: 'Șterge tot din listă',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: visibleRows.isEmpty
                              ? null
                              : () => _confirmDismissAll(visibleRows),
                          icon: Icon(
                            Icons.delete_sweep_rounded,
                            size: 22,
                            color: visibleRows.isEmpty
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (widget.onClose != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            tooltip: 'Închide',
                            icon: Icon(Icons.close_rounded,
                                size: 22, color: Colors.grey.shade700),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Online Friends
                  if (_onlineFriends.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${FirebaseAuth.instance.currentUser?.displayName ?? 'Vecin'} online acum (${_onlineFriends.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                        itemCount: _onlineFriends.length,
                        itemBuilder: (context, i) {
                          final p = _onlineFriends[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildProfileImage(
                                      photoURL: p.photoURL,
                                      avatar: p.avatar,
                                      size: 32,
                                      borderColor: const Color(0xFF22C55E),
                                    ),
                                    Positioned(
                                      bottom: -1,
                                      right: -1,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  width: 52,
                                  child: Text(
                                    p.displayName.isNotEmpty
                                        ? p.displayName
                                        : '—',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.grey.shade200,
                      indent: 12,
                      endIndent: 12,
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Activity Rows
                  if (visibleRows.isNotEmpty)
                    ...visibleRows.map((row) => Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildProfileImage(
                                photoURL: row.photoURL,
                                avatar: row.avatar,
                                size: 36,
                                borderColor: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      row.displayName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                    Text(
                                      row.text,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.2,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Șterge',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () => _dismissRow(row.id),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileImage({
    String? photoURL,
    required String avatar,
    required double size,
    required Color borderColor,
  }) {
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(photoURL),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasPhoto
          ? Center(
              child: Text(
                avatar,
                style: TextStyle(fontSize: size * 0.5),
              ),
            )
          : null,
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/models/chat_message_model.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Rând în lista de conversații 1:1 (private_chats).
class PrivateChatInboxRow {
  final String peerUid;
  final String displayName;
  final String avatarEmoji;
  final bool online;
  final String? lastPreview;
  final DateTime? lastAt;

  const PrivateChatInboxRow({
    required this.peerUid,
    required this.displayName,
    required this.avatarEmoji,
    required this.online,
    this.lastPreview,
    this.lastAt,
  });
}

/// Tab „Chat individual”: conversații private ca în lista principală de mesaje.
class PrivateChatInboxTab extends StatefulWidget {
  const PrivateChatInboxTab({
    super.key,
    required this.contacts,
    required this.onlineUids,
    required this.avatarCache,
    required this.friendPeerUids,
    required this.friendPeerProfileCache,
  });

  final List<ContactAppUser> contacts;
  final Set<String> onlineUids;
  final Map<String, String> avatarCache;
  final Set<String> friendPeerUids;
  final Map<String, ({String displayName, String avatar, String? photoURL})>
      friendPeerProfileCache;

  @override
  State<PrivateChatInboxTab> createState() => PrivateChatInboxTabState();
}

class PrivateChatInboxTabState extends State<PrivateChatInboxTab>
    with AutomaticKeepAliveClientMixin {
  final _db = FirebaseFirestore.instance;
  static const String _reactionPreviewMarker = '__reaction__';
  List<PrivateChatInboxRow> _rows = [];
  bool _loading = true;
  String? _error;

  /// uid -> URL poză profil sau null (rezolvat explicit).
  final Map<String, String?> _peerPhotoUrl = {};

  static const int _parallelChunk = 20;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(reloadThreads());
  }

  Future<void> _hydrateProfilePhotos(Set<String> uids) async {
    _peerPhotoUrl.clear();
    for (final u in uids) {
      final ph = widget.friendPeerProfileCache[u]?.photoURL;
      if (ph != null && ph.isNotEmpty) {
        _peerPhotoUrl[u] = ph;
      }
    }
    final needFetch = uids.where((u) => !_peerPhotoUrl.containsKey(u)).toList();
    if (needFetch.isEmpty) return;

    for (var i = 0; i < needFetch.length; i += _parallelChunk) {
      final end = math.min(i + _parallelChunk, needFetch.length);
      final chunk = needFetch.sublist(i, end);
      await Future.wait(
        chunk.map((uid) async {
          try {
            final d = await _db.collection('users').doc(uid).get();
            if (!mounted) return;
            final raw = (d.data()?['photoURL'] as String?)?.trim();
            _peerPhotoUrl[uid] =
                (raw != null && raw.isNotEmpty) ? raw : null;
          } catch (_) {
            if (mounted) _peerPhotoUrl[uid] = null;
          }
        }),
      );
    }
  }

  /// Reîncarcă lista (apelat la deschiderea tab-ului sau după revenirea din chat).
  Future<void> reloadThreads() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _loading = false;
          _error = l10n.privateChatNotAuthenticated;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final candidateUids = <String>{};
      for (final fp in widget.friendPeerUids) {
        if (fp.isNotEmpty && fp != myUid) candidateUids.add(fp);
      }
      for (final c in widget.contacts) {
        if (c.uid.isNotEmpty && c.uid != myUid) candidateUids.add(c.uid);
      }

      if (candidateUids.isEmpty) {
        if (mounted) {
          setState(() {
            _rows = [];
            _loading = false;
          });
        }
        return;
      }

      await _hydrateProfilePhotos(candidateUids);

      final uids = candidateUids.toList()..sort();
      final out = <PrivateChatInboxRow>[];

      for (var i = 0; i < uids.length; i += _parallelChunk) {
        final end = math.min(i + _parallelChunk, uids.length);
        final chunk = uids.sublist(i, end);
        final partial = await Future.wait(
          chunk.map((peerUid) => _loadRowForPeer(myUid, peerUid)),
        );
        out.addAll(partial);
      }

      out.sort((a, b) {
        final ah = a.lastAt != null;
        final bh = b.lastAt != null;
        if (ah != bh) return bh ? 1 : -1;
        if (ah && bh && a.lastAt != null && b.lastAt != null) {
          return b.lastAt!.compareTo(a.lastAt!);
        }
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });

      if (mounted) {
        setState(() {
          _rows = out;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<PrivateChatInboxRow> _loadRowForPeer(String myUid, String peerUid) async {
    final nameAndAvatar = _resolveNameAndAvatar(peerUid);
    final online = widget.onlineUids.contains(peerUid);

    final sorted = [myUid, peerUid]..sort();
    final chatId = sorted.join('_');

    String? preview;
    DateTime? lastAt;

    try {
      final snap = await _db
          .collection('private_chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        if (data['reaction'] == true) {
          preview = _reactionPreviewMarker;
        } else {
          final m = ChatMessage.fromMap(data);
          preview = _previewFromMessage(m);
        }
        final ts = data['timestamp'];
        if (ts is Timestamp) lastAt = ts.toDate();
      }
    } catch (e) {
      Logger.warning('PrivateChatInboxTab._buildRow failed: $e', tag: 'INBOX');
    }

    return PrivateChatInboxRow(
      peerUid: peerUid,
      displayName: nameAndAvatar.$1,
      avatarEmoji: nameAndAvatar.$2,
      online: online,
      lastPreview: preview,
      lastAt: lastAt,
    );
  }

  (String, String) _resolveNameAndAvatar(String peerUid) {
    for (final c in widget.contacts) {
      if (c.uid == peerUid) {
        final av = widget.avatarCache[peerUid] ?? '🙂';
        return (c.displayName.trim().isNotEmpty ? c.displayName.trim() : 'Utilizator', av);
      }
    }
    final fp = widget.friendPeerProfileCache[peerUid];
    if (fp != null) {
      return (fp.displayName, fp.avatar);
    }
    return ('Utilizator', '👤');
  }

  String? _photoUrlFor(String peerUid) {
    final u = _peerPhotoUrl[peerUid];
    if (u != null && u.isNotEmpty) return u;
    return null;
  }

  Widget _peerAvatar({
    required String peerUid,
    required String emoji,
    required bool online,
    required ColorScheme scheme,
  }) {
    final url = _photoUrlFor(peerUid);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
        border: Border.all(
          color: online ? const Color(0xFF22C55E) : scheme.outlineVariant,
          width: online ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                );
              },
            )
          : Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
    );
  }

  String _previewFromMessage(ChatMessage m) {
    switch (m.type) {
      case MessageType.image:
        return '📷 Fotografie';
      case MessageType.voice:
        return '🎤 Mesaj vocal';
      case MessageType.gif:
        return '🎬 GIF';
      case MessageType.location:
        return '📍 ${AppLocalizations.of(context)!.chatLocationLabel}';
      default:
        break;
    }
    final t = m.text.trim();
    if (t.isEmpty) return AppLocalizations.of(context)!.message;
    if (t.length > 72) return '${t.substring(0, 69)}…';
    return t;
  }

  String _displayPreview(String? preview, AppLocalizations l10n) {
    if (preview == _reactionPreviewMarker) return l10n.privateChatReaction;
    return preview ?? '';
  }

  void _openChat(PrivateChatInboxRow row) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final sorted = [myUid, row.peerUid]..sort();
    final roomId = sorted.join('_');

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          rideId: roomId,
          otherUserId: row.peerUid,
          otherUserName: row.displayName,
          collectionName: 'private_chats',
        ),
      ),
    ).then((_) {
      if (mounted) unawaited(reloadThreads());
    });
  }

  void _showNewChatSheet() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final uids = <String>{};
    for (final fp in widget.friendPeerUids) {
      if (fp.isNotEmpty && fp != myUid) uids.add(fp);
    }
    for (final c in widget.contacts) {
      if (c.uid.isNotEmpty && c.uid != myUid) uids.add(c.uid);
    }
    final list = uids.toList()
      ..sort((a, b) => _resolveNameAndAvatar(a).$1.toLowerCase().compareTo(
            _resolveNameAndAvatar(b).$1.toLowerCase(),
          ));

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Icon(Icons.forum_rounded, color: scheme.primary, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        l10n.privateChatNewChat,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.privateChatAddContactsToChoose,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: scheme.outlineVariant.withValues(alpha: 0.35)),
                          itemBuilder: (context, i) {
                            final uid = list[i];
                            final na = _resolveNameAndAvatar(uid);
                            final online = widget.onlineUids.contains(uid);
                            return ListTile(
                              leading: SizedBox(
                                width: 48,
                                height: 48,
                                child: _peerAvatar(
                                  peerUid: uid,
                                  emoji: na.$2,
                                  online: online,
                                  scheme: scheme,
                                ),
                              ),
                              title: Text(
                                na.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: online
                                  ? Text(
                                      l10n.privateChatOnMap,
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              trailing: Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16, color: scheme.onSurfaceVariant),
                              onTap: () {
                                Navigator.pop(ctx);
                                _openChat(PrivateChatInboxRow(
                                  peerUid: uid,
                                  displayName: na.$1,
                                  avatarEmoji: na.$2,
                                  online: online,
                                ));
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _timeLabel(BuildContext context, DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    final now = DateTime.now();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return DateFormat.Hm(localeTag).format(local);
    }
    if (local.year == now.year) {
      return DateFormat.MMMd(localeTag).format(local);
    }
    return DateFormat.yMd(localeTag).format(local);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
        ),
      );
    } else if (_rows.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '${l10n.privateChatNoPeopleYet}\n'
            '${l10n.privateChatAddContactsOrAcceptSuggestions}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_rounded,
                    size: 18, color: scheme.primary.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.privateChatConversationsHint,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: reloadThreads,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                itemCount: _rows.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: scheme.outlineVariant.withValues(alpha: 0.35)),
                itemBuilder: (context, i) {
                  final r = _rows[i];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openChat(r),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 22,
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                              ),
                            ),
                            _peerAvatar(
                              peerUid: r.peerUid,
                              emoji: r.avatarEmoji,
                              online: r.online,
                              scheme: scheme,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _displayPreview(r.lastPreview, l10n).isNotEmpty
                                        ? _displayPreview(r.lastPreview, l10n)
                                        : (r.online
                                            ? l10n.privateChatOnMapNowTapToWrite
                                            : l10n.privateChatTapToSendMessage),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _displayPreview(r.lastPreview, l10n).isNotEmpty
                                          ? scheme.onSurface.withValues(alpha: 0.72)
                                          : scheme.onSurfaceVariant,
                                      fontWeight: _displayPreview(r.lastPreview, l10n).isNotEmpty
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (r.lastAt != null)
                              Text(
                                _timeLabel(context, r.lastAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: body),
        if (!_loading && _error == null)
          Positioned(
            right: 16,
            bottom: 20,
            child: FloatingActionButton.extended(
              heroTag: 'privateChatInboxFab',
              onPressed: _showNewChatSheet,
              icon: const Icon(Icons.add_comment_rounded),
              label: Text(l10n.privateChatNewChat),
            ),
          ),
      ],
    );
  }
}

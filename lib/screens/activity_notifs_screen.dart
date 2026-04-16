import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_dismiss_store.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_service.dart';
import 'package:nabour_app/services/contacts_service.dart';

/// Ecran dedicat de notificări/activitate (Bell Screen).
/// Carduri bogate cu avatar, text, timestamp, CTA, red dot.
class ActivityNotificationsScreen extends StatefulWidget {
  final List<String> friendUids;
  final List<ContactAppUser> contacts;
  final Map<String, String> avatarCache;

  const ActivityNotificationsScreen({
    super.key,
    required this.friendUids,
    this.contacts = const [],
    this.avatarCache = const {},
  });

  @override
  State<ActivityNotificationsScreen> createState() =>
      _ActivityNotificationsScreenState();
}

class _ActivityNotificationsScreenState
    extends State<ActivityNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _bellRotation;
  StreamSubscription? _feedSub;
  List<ActivityEvent> _events = [];
  final Set<String> _readIds = {};
  Set<String> _dismissedNotifKeys = {};

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bellRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.04), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _bellController,
      curve: Curves.easeInOut,
    ));
    _bellController.forward();

    ActivityFeedDismissStore.loadNotifDismissed().then((s) {
      if (mounted) setState(() => _dismissedNotifKeys = s);
    });
    _subscribeToFeed();
  }

  List<ActivityEvent> get _visibleEvents => _events
      .where((e) => !_dismissedNotifKeys.contains(
            ActivityFeedDismissStore.notifCompositeKey(
                e.feedOwnerUid, e.id),
          ))
      .toList();

  Future<void> _dismissEvent(ActivityEvent e) async {
    await ActivityFeedDismissStore.dismissNotif(e.feedOwnerUid, e.id);
    if (!mounted) return;
    setState(() {
      _dismissedNotifKeys.add(
        ActivityFeedDismissStore.notifCompositeKey(e.feedOwnerUid, e.id),
      );
    });
  }

  Future<void> _confirmDismissAll() async {
    final visible = List<ActivityEvent>.from(_visibleEvents);
    if (visible.isEmpty) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ștergi toate cardurile?'),
        content: Text(
          'Se ascund ${visible.length} ${visible.length == 1 ? 'mesaj' : 'mesaje'} din Activitate pe acest dispozitiv.',
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
    final keys = visible
        .map((e) => ActivityFeedDismissStore.notifCompositeKey(
            e.feedOwnerUid, e.id))
        .toList();
    await ActivityFeedDismissStore.dismissAllNotif(keys);
    if (!mounted) return;
    setState(() => _dismissedNotifKeys = {..._dismissedNotifKeys, ...keys});
  }

  void _subscribeToFeed() {
    if (widget.friendUids.isEmpty) return;
    _feedSub = ActivityFeedService.instance
        .mergedFriendEvents(widget.friendUids, limit: 50)
        .listen(
      (events) {
        if (mounted) setState(() => _events = events);
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _bellController.dispose();
    _feedSub?.cancel();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'acum';
    if (diff.inMinutes < 60) return 'acum ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'acum ${diff.inHours} ore';
    if (diff.inDays == 1) return 'ieri';
    if (diff.inDays < 7) return 'acum ${diff.inDays} zile';
    return '${dt.day}.${dt.month}';
  }

  String _avatarFor(String uid) =>
      widget.avatarCache[uid] ?? '🙂';

  static bool _isProximityHit(String type) =>
      type == 'hit' || type == 'bump';

  String _ctaForType(String type) {
    switch (type) {
      case 'joined':
      case 'friend_joined':
        return 'Vezi ce fac acum!';
      case 'hit':
      case 'bump':
        return 'Trimite un mesaj!';
      case 'arrived_place':
      case 'left_place':
      case 'mystery_nearby':
      case 'mystery_opened':
        return 'Vezi pe hartă';
      case 'moment':
        return 'Vezi momentul';
      case 'neighborhood_request':
        return 'Vezi pe hartă';
      default:
        return 'Deschide';
    }
  }

  String _absoluteDateTime(BuildContext context, DateTime dt) {
    final loc = Localizations.localeOf(context);
    return DateFormat('dd.MM.yyyy HH:mm', loc.toString()).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Activitate',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Șterge tot',
                    onPressed:
                        _visibleEvents.isEmpty ? null : _confirmDismissAll,
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      color: _visibleEvents.isEmpty
                          ? cs.onSurface.withValues(alpha: 0.38)
                          : cs.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _bellRotation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _bellRotation.value,
                  child: child,
                );
              },
              child: const Text('🔔', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 20),

            if (_visibleEvents.isEmpty &&
                (widget.friendUids.isEmpty || _feedSub != null))
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Nicio activitate recentă',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _visibleEvents.length,
                itemBuilder: (context, i) => _buildEventCard(_visibleEvents[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(ActivityEvent event) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUnread = !_readIds.contains(event.id);
    final avatar = _avatarFor(event.actorUid);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _readIds.add(event.id));
          Navigator.pop(context, {
            'action': 'flyTo',
            'uid': event.actorUid,
            'lat': event.lat,
            'lng': event.lng,
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? cs.primaryContainer.withValues(alpha: 0.45)
                : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? cs.primary.withValues(alpha: 0.35)
                  : cs.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surface,
                  border: Border.all(
                    color: cs.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(avatar, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          event.actorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${_timeAgo(event.ts)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (event.type == 'neighborhood_request') ...[
                      const SizedBox(height: 2),
                      Text(
                        'Creată: ${_absoluteDateTime(context, event.ts)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _isProximityHit(event.type)
                          ? 'Hit, ${event.actorName} ${event.text}'
                          : '${event.actorName} ${event.text}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.92),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ctaForType(event.type),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              IconButton(
                tooltip: 'Șterge',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => _dismissEvent(event),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: cs.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';
import 'package:nabour_app/models/radar_alert_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/location_cache_service.dart';
import 'package:nabour_app/services/radar_group_message_service.dart';
import 'package:nabour_app/utils/logger.dart';

class RadarGroupBroadcastSheet extends StatefulWidget {
  const RadarGroupBroadcastSheet({super.key, required this.neighbors});

  final List<NeighborLocation> neighbors;

  @override
  State<RadarGroupBroadcastSheet> createState() =>
      _RadarGroupBroadcastSheetState();
}

class _RadarGroupBroadcastSheetState extends State<RadarGroupBroadcastSheet> {
  final _controller = TextEditingController();
  final _service = RadarGroupMessageService();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    final messageText = _controller.text.trim();
    if (messageText.isEmpty) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);

    // 1. Trimitem Broadcast-ul (FCM)
    final result = await _service.send(
      recipientUids: widget.neighbors.map((n) => n.uid).toList(),
      message: messageText,
    );

    if (result.success) {
      // 2. ✅ NOU: Salvăm în Firestore pentru persistență (Hartă / Feed)
      try {
        final user = FirebaseAuth.instance.currentUser;
        final pos = LocationCacheService.instance.peekRecent();
        
        if (user != null && pos != null) {
          final alert = RadarAlert(
            id: '', // Firestore will generate
            senderUid: user.uid,
            senderName: user.displayName ?? 'Vecin',
            message: messageText,
            latitude: pos.latitude,
            longitude: pos.longitude,
            timestamp: DateTime.now(),
            type: RadarAlertType.radar,
          );
          await FirestoreService().saveRadarAlert(alert);
        }
      } catch (e) {
        Logger.error('Failed to persist radar alert: $e', tag: 'RADAR');
      }
    }

    if (!mounted) return;
    setState(() => _sending = false);
    nav.pop();

    if (result.success) {
      final n = result.sent;
      final a = result.attempted;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            n >= a
                ? (a == 1
                    ? 'Mesaj trimis.'
                    : 'Mesaj trimis către $n persoane.')
                : 'Mesaj trimis către $n din $a (ceilalți fără notificări push active).',
          ),
          backgroundColor: const Color(0xFF166534),
        ),
      );
    } else {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Nu s-a putut trimite.'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.campaign_rounded, size: 44, color: Color(0xFF7C3AED)),
              const SizedBox(height: 12),
              Text(
                widget.neighbors.length == 1
                    ? 'Mesaj pentru ${widget.neighbors.first.displayName}'
                    : 'Mesaj pentru ${widget.neighbors.length} persoane din zonă',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Primește notificare push fiecare vecin care are aplicația și notificările activate.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: cs.onSurface),
                cursorColor: cs.primary,
                decoration: InputDecoration(
                  hintText: 'Scrie mesajul aici…',
                  hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.45)),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _sending ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'TRIMITE MESAJUL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Anulează',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

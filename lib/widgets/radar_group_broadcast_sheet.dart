import 'package:flutter/material.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';
import 'package:nabour_app/services/radar_group_message_service.dart';

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
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);
    final result = await _service.send(
      recipientUids: widget.neighbors.map((n) => n.uid).toList(),
      message: _controller.text,
    );
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
                ? 'Mesaj trimis către $n vecini.'
                : 'Mesaj trimis către $n din $a vecini (ceilalți fără notificări push active).',
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.campaign_rounded, size: 44, color: Color(0xFF7C3AED)),
              const SizedBox(height: 12),
              Text(
                'Mesaj pentru ${widget.neighbors.length} vecini',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C3AED),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Primește notificare push fiecare vecin care are aplicația și notificările activate.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Scrie mesajul aici…',
                  filled: true,
                  fillColor: Colors.grey.shade100,
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
                child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

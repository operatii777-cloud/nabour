import 'package:flutter/material.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_model.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_service.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/utils/content_filter.dart';

class MagicEventCreateScreen extends StatefulWidget {
  final BusinessProfile profile;

  const MagicEventCreateScreen({super.key, required this.profile});

  @override
  State<MagicEventCreateScreen> createState() => _MagicEventCreateScreenState();
}

class _MagicEventCreateScreenState extends State<MagicEventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();

  double _radiusM = 300;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 8));
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (t == null || !mounted) return;
    setState(() {
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 2));
      }
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end.isAfter(_start) ? _end : _start,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (t == null || !mounted) return;
    setState(() {
      _end = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final titleCheck = ContentFilter.check(_titleCtrl.text);
    if (!titleCheck.isClean) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(titleCheck.message ?? 'Titlu incorect.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data de sfârșit trebuie să fie după început.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final p = widget.profile;
      final sub = _subtitleCtrl.text.trim();
      final ev = MagicEvent(
        id: '',
        businessId: p.id,
        latitude: p.latitude,
        longitude: p.longitude,
        radiusMeters: _radiusM,
        startAt: _start,
        endAt: _end,
        title: _titleCtrl.text.trim(),
        subtitle: sub.isEmpty ? null : sub,
        geohash: '',
        isActive: true,
        participantCount: 0,
      );
      await MagicEventService.instance.createEvent(ev);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Eveniment magic')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Zona folosește coordonatele din profilul de business:\n'
              '${p.address}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titlu (ex. Festival de primăvară)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 3) return 'Minim 3 caractere';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Subtitlu (opțional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Text('Rază: ${_radiusM.round()} m',
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              min: 100,
              max: 500,
              divisions: 16,
              label: '${_radiusM.round()} m',
              value: _radiusM,
              onChanged: (v) => setState(() => _radiusM = v),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Început'),
              subtitle: Text(_start.toString().substring(0, 16)),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: _pickStart,
            ),
            ListTile(
              title: const Text('Sfârșit'),
              subtitle: Text(_end.toString().substring(0, 16)),
              trailing: const Icon(Icons.event_rounded),
              onTap: _pickEnd,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_loading ? 'Se salvează…' : 'Publică evenimentul'),
            ),
          ],
        ),
      ),
    );
  }
}

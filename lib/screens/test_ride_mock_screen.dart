import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/screens/searching_for_driver_screen.dart';
import 'package:nabour_app/utils/test_mode_helper.dart';

/// Flux mock pasager: aceleași colecții ca producția (`ride_requests`, `driver_locations`).
class TestRideMockScreen extends StatefulWidget {
  const TestRideMockScreen({super.key});

  @override
  State<TestRideMockScreen> createState() => _TestRideMockScreenState();
}

class _TestRideMockScreenState extends State<TestRideMockScreen> {
  final _log = StringBuffer();
  final _scroll = ScrollController();
  MockRideFlowOrchestrator? _orch;
  bool _busy = false;
  bool _autoConfirm = true;
  bool _toInProgress = true;
  String? _rideId;
  String? _driverId;

  void _append(String s) {
    setState(() {
      _log.writeln('[${DateTime.now().toIso8601String().substring(11, 19)}] $s');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _prepare() async {
    setState(() => _busy = true);
    try {
      final id = await TestModeHelper.prepareTestAccounts();
      if (!mounted) return;
      if (id == null) {
        _append('Eroare: pregătire conturi (login Firebase?)');
      } else {
        _driverId = id;
        _append('Conturi OK. driverId=$id, pasager=${FirebaseAuth.instance.currentUser?.uid}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelMyActiveRides() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('passengerId', isEqualTo: uid)
          .where('status', whereIn: [
            'pending',
            'searching',
            'driver_found',
            'accepted',
            'arrived',
            'in_progress',
          ])
          .get();
      for (final d in snap.docs) {
        await d.reference.update({
          'status': 'cancelled',
          'wasCancelled': true,
          'cancelledBy': uid,
        });
      }
      if (mounted) _append('Anulate ${snap.docs.length} curse active.');
    } catch (e) {
      _append('Eroare anulare: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createRideAndOpenSearch({bool startSimulation = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final driver = _driverId ?? TestModeHelper.lastPreparedDriverUid;
    if (uid == null || driver == null) {
      _append('Rulează mai întâi „Pregătire conturi”.');
      return;
    }
    _driverId = driver;
    setState(() => _busy = true);
    try {
      final rid = await TestModeHelper.createMockRideRequest(uid);
      if (!mounted) return;
      if (rid == null) {
        _append('Nu s-a putut crea cursa.');
        return;
      }
      _rideId = rid;
      if (startSimulation) {
        _orch?.cancel();
        _orch = MockRideFlowOrchestrator();
        _append('Cursă $rid — simularea pornește în fundal (2s → driver_found)');
        Future<void>.microtask(() => _orch!.runPassengerJourney(
              rideId: rid,
              driverId: driver,
              log: _append,
              autoConfirmDriver: _autoConfirm,
              advanceToInProgress: _toInProgress,
            ));
      } else {
        _append('Cursă creată: $rid — deschide căutarea; apoi „Simulare” din acest ecran.');
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (ctx) => SearchingForDriverScreen(rideId: rid),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startOrchestrator() {
    final rid = _rideId;
    final did = _driverId ?? TestModeHelper.lastPreparedDriverUid;
    if (rid == null || did == null) {
      _append('Lipsește rideId sau driverId — creează cursa mai întâi.');
      return;
    }
    _orch?.cancel();
    _orch = MockRideFlowOrchestrator();
    _append('Pornesc simularea pe $rid …');
    _orch!.runPassengerJourney(
      rideId: rid,
      driverId: did,
      log: _append,
      autoConfirmDriver: _autoConfirm,
      advanceToInProgress: _toInProgress,
    );
  }

  @override
  void dispose() {
    _orch?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode && !TestModeHelper.isTestMode) {
      return const Scaffold(
        body: Center(child: Text('Disponibil doar în debug / TEST_MODE.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock cursă (test)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Flux ca în producție: ride_requests + driver_locations. '
              'Deploy firestore.rules (pasager test → GPS șofer test).',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Confirmă șoferul automat'),
              value: _autoConfirm,
              onChanged: _busy ? null : (v) => setState(() => _autoConfirm = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('După accept: trece la in_progress'),
              value: _toInProgress,
              onChanged: _busy ? null : (v) => setState(() => _toInProgress = v),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _busy ? null : _prepare,
                  child: const Text('1. Pregătire conturi'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _cancelMyActiveRides,
                  child: const Text('Curăță cursele mele'),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _createRideAndOpenSearch(startSimulation: true),
                  child: const Text('Flux complet (recomandat)'),
                ),
                FilledButton.tonal(
                  onPressed: _busy ? null : () => _createRideAndOpenSearch(),
                  child: const Text('2. Doar cursă + căutare'),
                ),
                FilledButton(
                  onPressed: _busy ? null : _startOrchestrator,
                  child: const Text('3. Doar simulare'),
                ),
                OutlinedButton(
                  onPressed: () {
                    _orch?.cancel();
                    _append('Simulare oprită.');
                  },
                  child: const Text('Stop simulare'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Jurnal:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: SelectableText(
                    _log.isEmpty ? '—' : _log.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

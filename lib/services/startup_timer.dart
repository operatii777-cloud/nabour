import 'dart:developer' as developer;

class StartupTimer {
  StartupTimer._();
  static final StartupTimer instance = StartupTimer._();

  final DateTime _t0 = DateTime.now();
  final Map<String, DateTime> _marks = <String, DateTime>{};

  void mark(String name) {
    _marks.putIfAbsent(name, () => DateTime.now());
  }

  void log(String message) {
    developer.log(message, name: 'Startup');
  }

  void printSummary() {
    final entries = _marks.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    DateTime prev = _t0;
    log('=== Startup timeline ===');
    for (final e in entries) {
      final sinceStartMs = e.value.difference(_t0).inMilliseconds;
      final deltaMs = e.value.difference(prev).inMilliseconds;
      log('${sinceStartMs.toString().padLeft(5)} ms (+${deltaMs.toString().padLeft(3)} ms)  ${e.key}');
      prev = e.value;
    }
    log('========================');
  }
}




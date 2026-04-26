import 'package:cloud_firestore/cloud_firestore.dart';

/// Rezultatul unui apel [MapUniversalSearchMetricsService.loadPeopleMetrics].
class MapUniversalSearchPeopleMetrics {
  /// Numărul de prieteni comuni pe hartă, indexat după UID.
  final Map<String, int> friendCountByUid;

  /// UID-urile prietenilor comuni, indexate după UID-ul candidat.
  final Map<String, int> mutualFriendPeersByUid;

  const MapUniversalSearchPeopleMetrics({
    required this.friendCountByUid,
    required this.mutualFriendPeersByUid,
  });

  static const MapUniversalSearchPeopleMetrics empty =
      MapUniversalSearchPeopleMetrics(
    friendCountByUid: {},
    mutualFriendPeersByUid: {},
  );
}

/// Serviciu singleton care calculează metricile sociale ale utilizatorilor
/// vizibili în overlay-ul de căutare universală al hărții.
///
/// Rezultatele sunt menținute în memorie (cache per sesiune) — nu accesează
/// Firestore mai des de o dată per set de UID-uri.
class MapUniversalSearchMetricsService {
  MapUniversalSearchMetricsService._();
  static final MapUniversalSearchMetricsService instance =
      MapUniversalSearchMetricsService._();

  // Cache simplu: setul de UID-uri → rezultat
  Set<String>? _lastCandidateUids;
  MapUniversalSearchPeopleMetrics? _cached;

  /// Încarcă metricile sociale pentru [candidateUids], ținând cont de lista
  /// de prieteni existenți a utilizatorului curent ([myFriendPeerUids]).
  ///
  /// Returnează [MapUniversalSearchPeopleMetrics.empty] dacă nu există date.
  Future<MapUniversalSearchPeopleMetrics> loadPeopleMetrics({
    required Set<String> candidateUids,
    required Set<String> myFriendPeerUids,
  }) async {
    if (candidateUids.isEmpty) return MapUniversalSearchPeopleMetrics.empty;

    // Cache hit: același set de UID-uri
    if (_lastCandidateUids != null &&
        _setEquals(_lastCandidateUids!, candidateUids) &&
        _cached != null) {
      return _cached!;
    }

    final friendCountByUid = <String, int>{};
    final mutualFriendPeersByUid = <String, int>{};

    try {
      // Batch Firestore — maxim 30 UID-uri per query (limita `whereIn`)
      final batches = _chunk(candidateUids.toList(), 30);
      for (final batch in batches) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.serverAndCache));

        for (final doc in snap.docs) {
          final data = doc.data();
          final friends = List<String>.from(data['friendPeerUids'] as List? ?? []);
          friendCountByUid[doc.id] = friends.length;

          // Prieteni comuni = intersecția cu prietenii mei
          final mutual =
              friends.where((uid) => myFriendPeerUids.contains(uid)).length;
          mutualFriendPeersByUid[doc.id] = mutual;
        }
      }
    } catch (_) {
      // Eșec silențios — UI continuă fără metrici
      return MapUniversalSearchPeopleMetrics.empty;
    }

    final result = MapUniversalSearchPeopleMetrics(
      friendCountByUid: friendCountByUid,
      mutualFriendPeersByUid: mutualFriendPeersByUid,
    );
    _lastCandidateUids = Set<String>.from(candidateUids);
    _cached = result;
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      result.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return result;
  }
}

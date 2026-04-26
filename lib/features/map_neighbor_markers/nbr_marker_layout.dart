import 'dart:math' as math;

import 'package:geolocator/geolocator.dart' as geo;
import 'package:nabour_app/models/neighbor_location_model.dart';

class NeighborDisplayCoords {
  const NeighborDisplayCoords({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

class NeighborMarkerDisplayLayout {
  NeighborMarkerDisplayLayout._();

  /// Prietenii mai aproape decât această distanță sunt repoziționați
  /// în "trepte" (stack de carduri), astfel încât să nu se suprapună.
  /// GPS-ul poate împrăștia puncte „aceeași locație” pe zeci de metri —
  /// prag mai mare = grupare mai sigură.
  static const double mergeDistanceM = 110.0;
  static const double stairStepM = 24.0;

  static Map<String, NeighborDisplayCoords> compute(
    List<NeighborLocation> neighbors,
  ) {
    final result = <String, NeighborDisplayCoords>{};
    if (neighbors.isEmpty) return result;

    final n = neighbors.length;
    final dsu = _DisjointSet(n);

    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final d = geo.Geolocator.distanceBetween(
          neighbors[i].lat,
          neighbors[i].lng,
          neighbors[j].lat,
          neighbors[j].lng,
        );
        if (d <= mergeDistanceM) {
          dsu.union(i, j);
        }
      }
    }

    final groups = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      final r = dsu.find(i);
      groups.putIfAbsent(r, () => []).add(i);
    }

    for (final members in groups.values) {
      if (members.length == 1) {
        final nb = neighbors[members.first];
        result[nb.uid] = NeighborDisplayCoords(lat: nb.lat, lng: nb.lng);
        continue;
      }

      members.sort((a, b) => neighbors[a].uid.compareTo(neighbors[b].uid));

      var sumLat = 0.0;
      var sumLng = 0.0;
      for (final idx in members) {
        sumLat += neighbors[idx].lat;
        sumLng += neighbors[idx].lng;
      }
      final clat = sumLat / members.length;
      final clng = sumLng / members.length;
      final cosLat = math.cos(clat * math.pi / 180.0).abs().clamp(0.2, 1.0);
      // Adaptiv: puțini vecini => mai răsfirat, mulți => mai compact.
      final double scale = switch (members.length) {
        <= 2 => 1.35,
        <= 4 => 1.18,
        <= 7 => 1.0,
        <= 10 => 0.84,
        _ => 0.68,
      };
      final double stepM = (stairStepM * scale).clamp(8.0, 28.0);

      for (var k = 0; k < members.length; k++) {
        final idx = members[k];
        // "Pachet de cărți": fiecare următor marker este deplasat
        // puțin mai jos și spre dreapta (trepte diagonale).
        final downM = k * stepM;
        final rightM = k * stepM * 1.0;
        final dLat = (-downM) / 111320.0;
        final dLng = rightM / (111320.0 * cosLat);
        result[neighbors[idx].uid] =
            NeighborDisplayCoords(lat: clat + dLat, lng: clng + dLng);
      }
    }

    return result;
  }

  /// Returnează grupele de vecini co-localizați (≥2 membri) cu centroidul fiecăruia.
  static List<({List<NeighborLocation> members, double centerLat, double centerLng})>
      computeGroups(List<NeighborLocation> neighbors) {
    if (neighbors.length < 2) return [];
    final n = neighbors.length;
    final dsu = _DisjointSet(n);
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final d = geo.Geolocator.distanceBetween(
          neighbors[i].lat, neighbors[i].lng,
          neighbors[j].lat, neighbors[j].lng,
        );
        if (d <= mergeDistanceM) dsu.union(i, j);
      }
    }
    final groupsMap = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      groupsMap.putIfAbsent(dsu.find(i), () => []).add(i);
    }
    final result = <({List<NeighborLocation> members, double centerLat, double centerLng})>[];
    for (final indices in groupsMap.values) {
      if (indices.length < 2) continue;
      final members = indices.map((i) => neighbors[i]).toList();
      final clat = members.map((m) => m.lat).reduce((a, b) => a + b) / members.length;
      final clng = members.map((m) => m.lng).reduce((a, b) => a + b) / members.length;
      result.add((members: members, centerLat: clat, centerLng: clng));
    }
    return result;
  }
}

class _DisjointSet {
  _DisjointSet(int n) : _p = List.generate(n, (i) => i);

  final List<int> _p;

  int find(int i) {
    if (_p[i] != i) {
      _p[i] = find(_p[i]);
    }
    return _p[i];
  }

  void union(int a, int b) {
    final ra = find(a);
    final rb = find(b);
    if (ra != rb) {
      _p[rb] = ra;
    }
  }
}

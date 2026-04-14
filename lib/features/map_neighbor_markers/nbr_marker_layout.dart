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

  /// Prietenii mai aproape decât această distanță sunt repoziționați pe spirală (nu se suprapun).
  /// GPS-ul poate împrăștia puncte „aceeași locație” pe zeci de metri — prag mai mare = grupare mai sigură.
  static const double mergeDistanceM = 95.0;
  static const double baseRadiusM = 28.0;
  static const double spiralStepM = 18.0;

  static final double _goldenAngle =
      math.pi * (3.0 - math.sqrt(5.0));

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

      for (var k = 0; k < members.length; k++) {
        final idx = members[k];
        final theta = k * _goldenAngle;
        final rM = baseRadiusM + spiralStepM * math.sqrt(k + 1.0);
        final dLat = (rM * math.cos(theta)) / 111320.0;
        final dLng = (rM * math.sin(theta)) / (111320.0 * cosLat);
        result[neighbors[idx].uid] =
            NeighborDisplayCoords(lat: clat + dLat, lng: clng + dLng);
      }
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

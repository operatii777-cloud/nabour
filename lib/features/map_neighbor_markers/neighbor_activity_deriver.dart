import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';

class NeighborActivityRow {
  final String id;
  final String text;
  final String avatar;
  final String? photoURL;
  final String displayName;
  final DateTime sortKey;

  NeighborActivityRow({
    required this.id,
    required this.text,
    this.avatar = '🙂',
    this.photoURL,
    required this.displayName,
    required this.sortKey,
  });
}

class _PrevNeighbor {
  final String? placeKind;
  final double lat;
  final double lng;

  _PrevNeighbor({
    required this.placeKind,
    required this.lat,
    required this.lng,
  });
}

/// Rânduri pentru feed: evenimente scurte la schimbare + linie de stare per vecin.
class NeighborActivityDeriver {
  final Map<String, _PrevNeighbor> _prev = {};
  final Set<String> _firedTransitions = {};

  List<NeighborActivityRow> derive(List<NeighborLocation> current) {
    final rows = <NeighborActivityRow>[];
    final now = DateTime.now();

    for (final n in current) {
      final prev = _prev[n.uid];
      if (prev != null) {
        _maybeAddPlaceTransition(
          rows,
          uid: n.uid,
          name: n.displayName,
          avatar: n.avatar,
          photoURL: n.photoURL,
          from: prev.placeKind,
          to: n.placeKind,
          at: now,
        );

        final moved = Geolocator.distanceBetween(
          prev.lat,
          prev.lng,
          n.lat,
          n.lng,
        );
        if (moved > 200 &&
            (n.speedMps == null || n.speedMps! > 1.0)) {
          final id = '${n.uid}_mv_${n.lastUpdate.millisecondsSinceEpoch}';
          if (!_firedTransitions.contains(id)) {
            _firedTransitions.add(id);
            rows.add(NeighborActivityRow(
              id: id,
              text: 's-a deplasat',
              avatar: n.avatar,
              photoURL: n.photoURL,
              displayName: n.displayName,
              sortKey: n.lastUpdate,
            ));
          }
        }
      }

      _prev[n.uid] = _PrevNeighbor(
        placeKind: n.placeKind,
        lat: n.lat,
        lng: n.lng,
      );

      rows.add(NeighborActivityRow(
        id: 'st_${n.uid}',
        text: _statusLine(n),
        avatar: n.avatar,
        photoURL: n.photoURL,
        displayName: n.displayName,
        sortKey: n.lastUpdate,
      ));
    }

    final uids = current.map((e) => e.uid).toSet();
    _prev.removeWhere((k, _) => !uids.contains(k));
    if (_firedTransitions.length > 40) {
      _firedTransitions.clear();
    }

    rows.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return rows;
  }

  void _maybeAddPlaceTransition(
    List<NeighborActivityRow> rows, {
    required String uid,
    required String name,
    String avatar = '🙂',
    String? photoURL,
    required String? from,
    required String? to,
    required DateTime at,
  }) {
    if (from == to) return;
    String? text;
    if (from == 'home' && to != 'home') {
      text = 'a plecat de acasă';
    } else if (from != 'home' && to == 'home') {
      text = 'a ajuns acasă';
    } else if (from == 'work' && to != 'work') {
      text = 'a plecat de la serviciu';
    } else if (from != 'work' && to == 'work') {
      text = 'a ajuns la serviciu';
    } else if (from == 'school' && to != 'school') {
      text = 'a plecat de la școală';
    } else if (from != 'school' && to == 'school') {
      text = 'a ajuns la școală / facultate';
    }
    if (text == null) return;
    final id =
        '${uid}_${from}_${to}_${at.millisecondsSinceEpoch ~/ 15000}';
    if (_firedTransitions.contains(id)) return;
    _firedTransitions.add(id);
    rows.add(NeighborActivityRow(
      id: id,
      text: text,
      avatar: avatar,
      photoURL: photoURL,
      displayName: name,
      sortKey: at,
    ));
  }

  static String _statusLine(NeighborLocation n) {
    if (n.stationarySinceMs != null &&
        (n.speedMps == null || n.speedMps! < 1.2)) {
      final mins = DateTime.now()
          .difference(
            DateTime.fromMillisecondsSinceEpoch(n.stationarySinceMs!),
          )
          .inMinutes;
      if (mins >= 12) {
        return 'staționează de ${_formatMinutes(mins)}';
      }
    }
    switch (n.placeKind) {
      case 'home':
        return 'e acasă';
      case 'work':
        return 'e la serviciu';
      case 'school':
        return 'e la școală / facultate';
      default:
        break;
    }
    if (n.isDriver || n.activityStatus == 'driving') {
      return 'conduce acum';
    }
    final ago = DateTime.now().difference(n.lastUpdate).inMinutes;
    if (ago <= 0) {
      return 'online acum';
    }
    return 'văzut acum $ago min';
  }

  static String _formatMinutes(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    if (r == 0) return '$h h';
    return '$h h $r min';
  }
}

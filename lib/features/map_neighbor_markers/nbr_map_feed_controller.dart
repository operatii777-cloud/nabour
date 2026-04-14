import 'package:flutter/foundation.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';

/// Sursă unică pentru lista de vecini afișată în feed-ul de activitate (fără subscribe dublu RTDB).
class NeighborMapFeedController {
  NeighborMapFeedController._();
  static final NeighborMapFeedController instance = NeighborMapFeedController._();

  final ValueNotifier<List<NeighborLocation>> neighbors =
      ValueNotifier<List<NeighborLocation>>(<NeighborLocation>[]);

  void setNeighbors(List<NeighborLocation> next) {
    neighbors.value = List<NeighborLocation>.from(next);
  }
}

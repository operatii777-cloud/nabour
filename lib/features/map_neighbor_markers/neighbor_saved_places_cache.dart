import 'dart:async';

import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/services/firestore_service.dart';

/// Cache pentru adresele salvate ale userului curent (Acasă / Serviciu / etc.).
class NeighborSavedPlacesCache {
  NeighborSavedPlacesCache._();
  static final NeighborSavedPlacesCache instance = NeighborSavedPlacesCache._();

  StreamSubscription<List<SavedAddress>>? _sub;
  List<SavedAddress> _latest = [];

  List<SavedAddress> get latest => List.unmodifiable(_latest);

  Future<void> ensureSubscribed() async {
    if (_sub != null) return;
    _sub = FirestoreService().getSavedAddresses().listen(
      (list) => _latest = list,
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _latest = [];
  }
}

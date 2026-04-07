import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/services/nabour_functions.dart';
import 'package:nabour_app/utils/logger.dart';

/// Pin comunitar pe harta (raspuns de la callable).
class CommunityMysteryBoxPin {
  final String id;
  final double latitude;
  final double longitude;
  final String message;
  final String placerUid;
  final int rewardTokens;

  const CommunityMysteryBoxPin({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.message,
    required this.placerUid,
    required this.rewardTokens,
  });

  factory CommunityMysteryBoxPin.fromMap(String id, Map<String, dynamic> m) {
    return CommunityMysteryBoxPin(
      id: id,
      latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
      message: m['message'] as String? ?? '',
      placerUid: m['placerUid'] as String? ?? '',
      rewardTokens: (m['rewardTokens'] as num?)?.toInt() ?? 50,
    );
  }
}

class CommunityMysteryBoxService {
  CommunityMysteryBoxService._();
  static final CommunityMysteryBoxService instance =
      CommunityMysteryBoxService._();

  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<List<CommunityMysteryBoxPin>> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    if (_uid == null) return [];
    try {
      final res = await NabourFunctions.instance
          .httpsCallable('nabourCommunityMysteryBoxesNearby')
          .call<Map<String, dynamic>>({
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
      });
      final list = res.data['boxes'];
      if (list is! List) return [];
      final out = <CommunityMysteryBoxPin>[];
      for (final item in list) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final id = m['id'] as String? ?? '';
        if (id.isEmpty) continue;
        out.add(CommunityMysteryBoxPin.fromMap(id, m));
      }
      return out;
    } catch (e, st) {
      Logger.error('community fetchNearby: $e', error: e, stackTrace: st);
      return [];
    }
  }

  Future<String?> place({
    required double lat,
    required double lng,
    String message = '',
  }) async {
    if (_uid == null) return null;
    final res = await NabourFunctions.instance
        .httpsCallable('nabourCommunityMysteryBoxPlace')
        .call<Map<String, dynamic>>({
      'lat': lat,
      'lng': lng,
      'message': message,
    });
    return res.data['boxId'] as String?;
  }

  Future<int> claim({
    required String boxId,
    required double claimLat,
    required double claimLng,
  }) async {
    final res = await NabourFunctions.instance
        .httpsCallable('nabourCommunityMysteryBoxClaim')
        .call<Map<String, dynamic>>({
      'boxId': boxId,
      'claimLat': claimLat,
      'claimLng': claimLng,
    });
    return (res.data['reward'] as num?)?.toInt() ?? 50;
  }
}
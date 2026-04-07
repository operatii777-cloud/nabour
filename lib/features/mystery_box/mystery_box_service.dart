import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/business_offer_model.dart';
import 'package:nabour_app/services/nabour_functions.dart';
import 'package:nabour_app/utils/logger.dart';

class MysteryBoxClaimResult {
  final bool success;
  final bool alreadyOpenedToday;
  final String? redemptionCode;
  final int? remaining;
  final int? total;
  final int? claimed;

  const MysteryBoxClaimResult({
    required this.success,
    this.alreadyOpenedToday = false,
    this.redemptionCode,
    this.remaining,
    this.total,
    this.claimed,
  });

  static const failure = MysteryBoxClaimResult(success: false);
  static const alreadyToday =
      MysteryBoxClaimResult(success: false, alreadyOpenedToday: true);
}

class MysteryBoxService {
  static final MysteryBoxService _instance = MysteryBoxService._();
  factory MysteryBoxService() => _instance;
  MysteryBoxService._();

  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Deschide cutia atomic (plafon, 1/zi, +tokeni, cod reducere) — `nabourMysteryBoxClaim`.
  Future<MysteryBoxClaimResult> openBox(BusinessOffer offer) async {
    if (_uid == null) return MysteryBoxClaimResult.failure;

    try {
      final res = await NabourFunctions.instance
          .httpsCallable('nabourMysteryBoxClaim')
          .call<Map<String, dynamic>>({'offerId': offer.id});
      final data = res.data;
      final ok = data['ok'] == true;
      if (ok) {
        Logger.info(
          'Mystery Box opened at ${offer.businessName} (remaining=${data['remaining']}, code=${data['redemptionCode']})',
          tag: 'MysteryBox',
        );
        return MysteryBoxClaimResult(
          success: true,
          redemptionCode: data['redemptionCode'] as String?,
          remaining: (data['remaining'] as num?)?.toInt(),
          total: (data['total'] as num?)?.toInt(),
          claimed: (data['claimed'] as num?)?.toInt(),
        );
      }
      return MysteryBoxClaimResult.failure;
    } on FirebaseFunctionsException catch (e) {
      Logger.error(
        'openBox CF: ${e.code} ${e.message}',
        error: e,
        tag: 'MysteryBox',
      );
      if (e.code == 'already-exists') {
        return MysteryBoxClaimResult.alreadyToday;
      }
      rethrow;
    } catch (e) {
      Logger.error('openBox error: $e', error: e, tag: 'MysteryBox');
      rethrow;
    }
  }

  /// Verifică dacă utilizatorul a deschis deja caseta azi la magazinul respectiv.
  Future<bool> isBoxOpenedToday(String businessId) async {
    final uid = _uid;
    if (uid == null) return true;
    final docId =
        '${businessId}_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('opened_mystery_boxes')
        .doc(docId)
        .get();
    return snap.exists;
  }
}

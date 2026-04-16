import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/business_offer_model.dart';
import 'package:nabour_app/models/business_profile_model.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/logger.dart';

class BusinessService {
  static final BusinessService _instance = BusinessService._();
  factory BusinessService() => _instance;
  BusinessService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Collections ─────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection('business_profiles');

  CollectionReference<Map<String, dynamic>> get _offers =>
      _db.collection('business_offers');

  // ── Business Profile ─────────────────────────────────────────────────────────

  /// Returnează profilul de business al utilizatorului curent (sau null dacă nu există).
  Future<BusinessProfile?> getMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final snap = await _profiles.where('userId', isEqualTo: uid).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return BusinessProfile.fromFirestore(
          snap.docs.first as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      Logger.error('getMyProfile error', error: e, tag: 'BusinessService');
      return null;
    }
  }

  /// Stream live al profilului de business al utilizatorului curent.
  Stream<BusinessProfile?> get myProfileStream {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _profiles
        .where('userId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return BusinessProfile.fromFirestore(
          snap.docs.first as DocumentSnapshot<Map<String, dynamic>>);
    });
  }

  /// Creează un profil de business nou.
  Future<String> registerBusiness(BusinessProfile profile) async {
    final doc = await _profiles.add(profile.toMap());
    Logger.info('Business registered: ${profile.businessName}', tag: 'BusinessService');
    return doc.id;
  }

  /// Actualizează profilul existent.
  Future<void> updateProfile(String profileId, Map<String, dynamic> data) async {
    await _profiles.doc(profileId).update(data);
  }

  // ── Business Offers ──────────────────────────────────────────────────────────

  // ── Suspension / Reactivation ────────────────────────────────────────────────

  /// Suspendă profilul de business și dezactivează toate anunțurile sale.
  Future<void> suspendBusiness(String profileId) async {
    try {
      final batch = _db.batch();
      batch.update(_profiles.doc(profileId), {
        'isSuspended': true,
        'isActive': false,
      });
      final offers = await _offers
          .where('businessId', isEqualTo: profileId)
          .where('isActive', isEqualTo: true)
          .get();
      for (final doc in offers.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();
      Logger.info('Business suspendat: $profileId', tag: 'BusinessService');
    } catch (e) {
      Logger.error('suspendBusiness error', error: e, tag: 'BusinessService');
    }
  }

  /// Reactivează contul după reînnoire abonament.
  /// Anunțurile rămân dezactivate — comerciantul le reactivează manual.
  Future<void> reactivateBusiness(
      String profileId, DateTime newExpiresAt) async {
    try {
      await _profiles.doc(profileId).update({
        'isSuspended': false,
        'isActive': true,
        'subscriptionExpiresAt': Timestamp.fromDate(newExpiresAt),
      });
      Logger.info('Business reactivat: $profileId', tag: 'BusinessService');
    } catch (e) {
      Logger.error('reactivateBusiness error', error: e, tag: 'BusinessService');
    }
  }

  /// Verifică dacă abonamentul a expirat și suspendă automat dacă da.
  /// Returnează true dacă suspendarea a fost aplicată.
  Future<bool> checkAndSuspendIfExpired(BusinessProfile profile) async {
    if (profile.isSuspended) return false; // deja suspendat
    final exp = profile.subscriptionExpiresAt;
    if (exp == null) return false; // fără abonament → nu expiră
    if (DateTime.now().isBefore(exp)) return false; // încă activ
    await suspendBusiness(profile.id);
    return true;
  }

  // ── Business Offers ──────────────────────────────────────────────────────────

  /// Creează un anunț nou. Costă [TokenCost.businessOffer] + opțional [TokenCost.mysteryBoxSlot] per cutie cu plafon.
  /// Returnează id-ul anunțului sau aruncă excepție dacă tokenii sunt insuficienți.
  Future<String> createOffer(BusinessOffer offer) async {
    final uid = _uid;
    if (uid == null) throw Exception('Utilizator neautentificat');

    // Verifică dacă business-ul nu e suspendat
    final profile = await getMyProfile();
    if (profile != null && profile.isSuspended) {
      throw const SuspendedBusinessException(
          'Contul este suspendat. Reînnoiți abonamentul pentru a posta anunțuri.');
    }

    final slots = offer.mysteryBoxTotal ?? 0;
    final mysteryCost = TokenCost.mysteryBoxSlotsTokenCost(slots);
    final totalCost = TokenCost.businessOffer + mysteryCost;
    final desc = mysteryCost > 0
        ? 'Anunț business: ${offer.title} (+ $slots × Mystery Box)'
        : 'Anunț business: ${offer.title}';

    final result = await TokenService().spendAmount(
      totalCost,
      type: TokenTransactionType.businessOffer,
      customDescription: desc,
    );

    if (!result.success) {
      throw InsufficientTokensException(result.errorMessage ?? 'Sold insuficient');
    }

    final doc = await _offers.add(offer.toMap());
    Logger.info('Offer created: ${offer.title}', tag: 'BusinessService');
    return doc.id;
  }

  /// Stream cu anunțurile proprii ale agentului economic.
  Stream<List<BusinessOffer>> myOffersStream(String businessId) {
    return _offers
        .where('businessId', isEqualTo: businessId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BusinessOffer.fromFirestore(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Incrementează viewsCount când un anunț apare în feed.
  Future<void> incrementViews(String offerId) async {
    try {
      await _offers.doc(offerId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      Logger.debug('incrementViews failed for $offerId: $e', tag: 'BusinessService');
    }
  }

  /// Sterge (dezactivează) un anunț.
  Future<void> deleteOffer(String offerId) async {
    await _offers.doc(offerId).update({'isActive': false});
    Logger.info('Offer deleted: $offerId', tag: 'BusinessService');
  }

  /// Actualizează un anunț existent. Creșterea plafonului Mystery Box costă tokeni (vezi [TokenCost.mysteryBoxSlot]).
  Future<void> updateOffer({
    required String offerId,
    required String title,
    required String description,
    String? link,
    String? phone,
    String? whatsapp,
    required bool isFlash,
    required BusinessProfile profile,
    /// `null` = păstrează capacitatea din Firestore; `0` = scoate plafonul; `>0` = nou plafon (≥ deja revendicate).
    int? mysteryBoxTotal,
  }) async {
    final p = await getMyProfile();
    if (p != null && p.isSuspended) {
      throw const SuspendedBusinessException(
          'Contul este suspendat. Reînnoiți abonamentul pentru a modifica anunțuri.');
    }

    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'isFlash': isFlash,
      'businessName': profile.businessName,
      'businessCategory': profile.category.name,
      'businessLatitude': profile.latitude,
      'businessLongitude': profile.longitude,
    };
    if (link == null || link.isEmpty) {
      data['link'] = FieldValue.delete();
    } else {
      data['link'] = link;
    }
    if (phone == null || phone.isEmpty) {
      data['phone'] = FieldValue.delete();
    } else {
      data['phone'] = phone;
    }
    if (whatsapp == null || whatsapp.isEmpty) {
      data['whatsapp'] = FieldValue.delete();
    } else {
      data['whatsapp'] = whatsapp;
    }

    if (mysteryBoxTotal != null) {
      if (mysteryBoxTotal <= 0) {
        data['mysteryBoxTotal'] = FieldValue.delete();
      } else {
        final cur = await _offers.doc(offerId).get();
        final claimed =
            (cur.data()?['mysteryBoxClaimed'] as num?)?.toInt() ?? 0;
        if (mysteryBoxTotal < claimed) {
          throw Exception(
            'Nu poți seta mai puțin de $claimed cutii (deja revendicate).',
          );
        }
        final oldRaw = cur.data()?['mysteryBoxTotal'];
        final oldTotal = (oldRaw is num && oldRaw.toInt() > 0)
            ? oldRaw.toInt()
            : 0;
        final addSlots = mysteryBoxTotal - oldTotal;
        if (addSlots > 0) {
          final mbCost = TokenCost.mysteryBoxSlotsTokenCost(addSlots);
          final spend = await TokenService().spendAmount(
            mbCost,
            type: TokenTransactionType.businessOffer,
            customDescription:
                'Mystery Box: +$addSlots cutii (anunț $offerId)',
          );
          if (!spend.success) {
            throw InsufficientTokensException(
                spend.errorMessage ?? 'Sold insuficient');
          }
        }
        data['mysteryBoxTotal'] = mysteryBoxTotal;
      }
    }

    await _offers.doc(offerId).update(data);
    Logger.info('Offer updated: $offerId', tag: 'BusinessService');
  }

  /// Actualizează profilul și propagă numele/categoria/coordonatele pe toate anunțurile afacerii.
  Future<void> updateProfileWithOfferSync(BusinessProfile updated) async {
    final data = <String, dynamic>{
      'businessName': updated.businessName,
      'category': updated.category.name,
      'address': updated.address,
      'phone': updated.phone,
      'description': updated.description,
      'latitude': updated.latitude,
      'longitude': updated.longitude,
      'location': GeoPoint(updated.latitude, updated.longitude),
    };
    if (updated.website == null || updated.website!.isEmpty) {
      data['website'] = FieldValue.delete();
    } else {
      data['website'] = updated.website;
    }
    if (updated.whatsapp == null || updated.whatsapp!.isEmpty) {
      data['whatsapp'] = FieldValue.delete();
    } else {
      data['whatsapp'] = updated.whatsapp;
    }

    await _profiles.doc(updated.id).update(data);

    final snap =
        await _offers.where('businessId', isEqualTo: updated.id).get();
    const chunk = 450;
    var batch = _db.batch();
    var n = 0;
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'businessName': updated.businessName,
        'businessCategory': updated.category.name,
        'businessLatitude': updated.latitude,
        'businessLongitude': updated.longitude,
      });
      n++;
      if (n >= chunk) {
        await batch.commit();
        batch = _db.batch();
        n = 0;
      }
    }
    if (n > 0) await batch.commit();
    Logger.info('Profile + offers synced: ${updated.id}', tag: 'BusinessService');
  }

  /// Query anunțuri în raza de 6km față de utilizator.
  /// Folosim bounding box pe Firestore + filtru distanță client-side.
  Future<List<BusinessOffer>> getNearbyOffers({
    required double userLat,
    required double userLng,
    double radiusKm = 6.0,
  }) async {
    // 1 grad latitudine ≈ 111km
    final latDelta = radiusKm / 111.0;
    // 1 grad longitudine la lat. 45° ≈ 78.5km
    final lngDelta = radiusKm / (111.0 * math.cos(userLat * math.pi / 180));

    final minLat = userLat - latDelta;
    final maxLat = userLat + latDelta;
    final minLng = userLng - lngDelta;
    final maxLng = userLng + lngDelta;

    try {
      final snap = await _offers
          .where('isActive', isEqualTo: true)
          .where('businessLatitude', isGreaterThanOrEqualTo: minLat)
          .where('businessLatitude', isLessThanOrEqualTo: maxLat)
          .orderBy('businessLatitude')
          .orderBy('createdAt', descending: true)
          .get();

      // Filtru client-side pentru longitudine și distanță exactă + attach distanță
      final results = <BusinessOffer>[];
      for (final d in snap.docs) {
        final rawOffer = BusinessOffer.fromFirestore(
            d as DocumentSnapshot<Map<String, dynamic>>);
        final offer = _normalizeBubbleTheaCategory(rawOffer, d.id);
        if (offer.businessLongitude < minLng ||
            offer.businessLongitude > maxLng) { continue; }
        final km = _distanceKm(
            userLat, userLng, offer.businessLatitude, offer.businessLongitude);
        if (km > radiusKm) { continue; }
        results.add(offer.withDistance(km));
      }
      // Flash-urile apar primele, restul ordonate după distanță
      results.sort((a, b) {
        if (a.isFlash && !b.isFlash) return -1;
        if (!a.isFlash && b.isFlash) return 1;
        return (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999);
      });
      return results;
    } catch (e) {
      Logger.error('getNearbyOffers error', error: e, tag: 'BusinessService');
      return [];
    }
  }

  BusinessOffer _normalizeBubbleTheaCategory(BusinessOffer offer, String docId) {
    final name = offer.businessName.toLowerCase();
    final title = offer.title.toLowerCase();
    final isBubbleThea = name.contains('bubble thea') || title.contains('bubble thea');
    if (!isBubbleThea) return offer;
    if (offer.businessCategory == BusinessCategory.foodTruck) return offer;

    // Normalizare doar în memorie — update pe document e doar pentru proprietar (reguli Firestore).

    return BusinessOffer(
      id: offer.id,
      businessId: offer.businessId,
      businessName: offer.businessName,
      businessCategory: BusinessCategory.foodTruck,
      businessLatitude: offer.businessLatitude,
      businessLongitude: offer.businessLongitude,
      title: offer.title,
      description: offer.description,
      link: offer.link,
      phone: offer.phone,
      whatsapp: offer.whatsapp,
      isFlash: offer.isFlash,
      viewsCount: offer.viewsCount,
      createdAt: offer.createdAt,
      isActive: offer.isActive,
      mysteryBoxTotal: offer.mysteryBoxTotal,
      mysteryBoxClaimed: offer.mysteryBoxClaimed,
      distanceKm: offer.distanceKm,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Distanță Haversine în km între două coordonate.
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class InsufficientTokensException implements Exception {
  final String message;
  const InsufficientTokensException(this.message);
  @override
  String toString() => message;
}

class SuspendedBusinessException implements Exception {
  final String message;
  const SuspendedBusinessException(this.message);
  @override
  String toString() => message;
}

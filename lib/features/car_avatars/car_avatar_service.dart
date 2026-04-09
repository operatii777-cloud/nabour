import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_model.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/logger.dart';

class CarAvatarService {
  static final CarAvatarService _instance = CarAvatarService._();
  factory CarAvatarService() => _instance;
  CarAvatarService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Cache scurt pentru a evita dubla citire Firestore când harta încarcă ambele sloturi.
  String? _purchasedIdsCacheUid;
  Set<String>? _purchasedIdsCache;
  DateTime? _purchasedIdsCacheAt;

  void _clearPurchasedAvatarCache() {
    _purchasedIdsCache = null;
    _purchasedIdsCacheAt = null;
    _purchasedIdsCacheUid = null;
  }

  final List<CarAvatar> _allAvatars = [
    CarAvatar.defaultCar(),
    // --- Transport ---
    CarAvatar(id: 'ufo', name: 'OZN Galactic', assetPath: 'assets/images/avatars/ufo.png', price: 500, category: CarCategory.transport),
    CarAvatar(id: 'rocket', name: 'Racheta Nabour', assetPath: 'assets/images/avatars/rocket.png', price: 750, category: CarCategory.transport),
    CarAvatar(id: 'dacia', name: 'Dacia Clasica', assetPath: 'assets/images/avatars/dacia.png', price: 300, category: CarCategory.transport),
    CarAvatar(id: 'carpet', name: 'Covor Fermecat', assetPath: 'assets/images/avatars/carpet.png', price: 1000, category: CarCategory.transport),
    CarAvatar(id: 'van', name: 'Dubita Livrare', assetPath: 'assets/images/avatars/van.png', price: 250, category: CarCategory.transport),
    CarAvatar(id: 'limo', name: 'Limuzina Lux', assetPath: 'assets/images/avatars/limo.png', price: 850, category: CarCategory.transport),
    CarAvatar(id: 'pickup', name: 'Camioneta Marfa', assetPath: 'assets/images/avatars/pickup.png', price: 400, category: CarCategory.transport),
    CarAvatar(id: 'barbie', name: 'Masina Barbie', assetPath: 'assets/images/avatars/barbie.png', price: 600, category: CarCategory.transport),
    CarAvatar(id: 'electric', name: 'Masina E-Tech', assetPath: 'assets/images/avatars/electric.png', price: 550, category: CarCategory.transport),
    CarAvatar(id: 'scooter', name: 'Trotineta Urbana', assetPath: 'assets/images/avatars/scooter.png', price: 150, category: CarCategory.transport),
    CarAvatar(id: 'moto', name: 'Motocicleta Sport', assetPath: 'assets/images/avatars/moto.png', price: 450, category: CarCategory.transport),
    CarAvatar(id: 'yacht', name: 'Iaht Diamond', assetPath: 'assets/images/avatars/yacht.png', price: 2500, category: CarCategory.transport),
    CarAvatar(id: 'uber', name: 'Uber Prototype', assetPath: 'assets/images/avatars/uber.png', price: 1250, category: CarCategory.transport),
    CarAvatar(id: 'salupa', name: 'Salupa Rapida', assetPath: 'assets/images/avatars/salupa.png', price: 1200, category: CarCategory.transport),
    // --- Animals ---
    CarAvatar(id: 'horse', name: 'Cal de Curse', assetPath: 'assets/images/avatars/horse.png', price: 1500, category: CarCategory.animals),
    CarAvatar(id: 'rhino', name: 'Rinocer Blindat', assetPath: 'assets/images/avatars/rhino.png', price: 2000, category: CarCategory.animals),
    CarAvatar(id: 'elephant', name: 'Elefant Maiestos', assetPath: 'assets/images/avatars/elephant.png', price: 2200, category: CarCategory.animals),
    // --- Characters (inclusiv ROBO — doar mod pasager pe hartă) ---
    CarAvatar(id: 'robo', name: 'ROBO', assetPath: 'assets/images/avatars/ROBO.png', price: 1800, category: CarCategory.characters),
    CarAvatar(id: 'unicorn', name: 'Unicorn Magic', assetPath: 'assets/images/avatars/unicorn.png', price: 5000, category: CarCategory.characters),
    CarAvatar(id: 'mythic', name: 'Erou Mitic', assetPath: 'assets/images/avatars/mythic.png', price: 3500, category: CarCategory.characters),
  ];

  List<CarAvatar> getAvailableAvatars() => _allAvatars;

  static const String kFieldDriver = 'selectedCarAvatarIdDriver';
  static const String kFieldPassenger = 'selectedCarAvatarIdPassenger';
  static const String kFieldLegacy = 'selectedCarAvatarId';

  /// Rezolvă ID-ul pentru un slot; dacă lipsește câmpul nou, folosește [kFieldLegacy].
  static String resolveSlotId(Map<String, dynamic>? data, CarAvatarMapSlot slot) {
    final d = data ?? {};
    final legacy = (d[kFieldLegacy] as String?)?.trim();
    switch (slot) {
      case CarAvatarMapSlot.driver:
        final v = (d[kFieldDriver] as String?)?.trim();
        if (v != null && v.isNotEmpty) return v;
        return (legacy != null && legacy.isNotEmpty) ? legacy : 'default_car';
      case CarAvatarMapSlot.passenger:
        final v = (d[kFieldPassenger] as String?)?.trim();
        if (v != null && v.isNotEmpty) return v;
        return (legacy != null && legacy.isNotEmpty) ? legacy : 'default_car';
    }
  }

  Future<String> getSelectedAvatarIdForSlot(CarAvatarMapSlot slot) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'default_car';
    final doc = await _db.collection('users').doc(uid).get();
    var id = resolveSlotId(doc.data(), slot);
    final av = getAvatarById(id);
    if (slot == CarAvatarMapSlot.driver && !av.allowsDriverMapSlot) {
      id = 'default_car';
    }
    if (slot == CarAvatarMapSlot.passenger && !av.allowsPassengerMapSlot) {
      id = 'default_car';
    }
    if (id == 'default_car') return id;

    // Profilul poate indica un skin premium fără document în `purchased_avatars`
    // (alt dispozitiv ne-sincronizat, date vechi, sau cont fără tokeni).
    // Pe hartă folosim doar ce e cumpărat / deblocat în garaj.
    final purchased = await getPurchasedAvatarIds();
    if (!purchased.contains(id)) {
      Logger.info(
        'Slot $slot: în profil este "$id", dar nu apare în garajul achiziționat — berlina implicită pe hartă.',
        tag: 'AVATAR',
      );
      return 'default_car';
    }
    return id;
  }

  /// @deprecated Folosește [getSelectedAvatarIdForSlot]; păstrat pentru compat — întoarce id-ul șoferului.
  Future<String> getSelectedAvatarId() =>
      getSelectedAvatarIdForSlot(CarAvatarMapSlot.driver);

  Future<Set<String>> getPurchasedAvatarIds({bool forceRefresh = false}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {'default_car'};

    final now = DateTime.now();
    if (!forceRefresh &&
        _purchasedIdsCacheUid == uid &&
        _purchasedIdsCache != null &&
        _purchasedIdsCacheAt != null &&
        now.difference(_purchasedIdsCacheAt!) < const Duration(seconds: 8)) {
      return _purchasedIdsCache!;
    }

    final snap =
        await _db.collection('users').doc(uid).collection('purchased_avatars').get();
    final ids = snap.docs.map((d) => d.id).toSet();
    ids.add('default_car');
    _purchasedIdsCache = ids;
    _purchasedIdsCacheAt = now;
    _purchasedIdsCacheUid = uid;
    return ids;
  }

  Future<bool> purchaseAvatar(
    CarAvatar avatar, {
    CarAvatarMapSlot applyToSlot = CarAvatarMapSlot.driver,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    if (avatar.comingSoon) return false;
    if (applyToSlot == CarAvatarMapSlot.driver && !avatar.allowsDriverMapSlot) {
      Logger.warning(
        'Cumpărare respinsă: ${avatar.id} nu se poate aplica la volan.',
        tag: 'AVATAR_SHOP',
      );
      return false;
    }
    if (applyToSlot == CarAvatarMapSlot.passenger && !avatar.allowsPassengerMapSlot) {
      Logger.warning(
        'Cumpărare respinsă: ${avatar.id} nu se poate aplica ca pasager pe hartă.',
        tag: 'AVATAR_SHOP',
      );
      return false;
    }

    try {
      // --- UNIFICARE ATOMICĂ: Debităm tokeni și deblocăm avatarul în aceeași tranzacție ---
      final success = await _db.runTransaction<bool>((transaction) async {
        final walletRef = _db.collection('users').doc(uid).collection('token_wallet').doc('wallet');
        final walletSnap = await transaction.get(walletRef);
        
        if (!walletSnap.exists) return false;
        
        final balance = (walletSnap.data()?['balance'] as num?)?.toInt() ?? 0;
        final plan = walletSnap.data()?['plan'] as String? ?? 'free';
        
        // Verificăm soldul
        if (plan != 'unlimited' && balance < avatar.price) return false;
        
        // 1. Deducem tokenii
        if (plan == 'unlimited') {
          transaction.update(walletRef, {'totalSpent': FieldValue.increment(avatar.price)});
        } else {
          transaction.update(walletRef, {
            'balance': FieldValue.increment(-avatar.price),
            'totalSpent': FieldValue.increment(avatar.price)
          });
        }
        
        // 2. Deblocăm avatarul în subcolecție
        final purchaseRef = _db.collection('users').doc(uid).collection('purchased_avatars').doc(avatar.id);
        transaction.set(purchaseRef, {
          'purchasedAt': FieldValue.serverTimestamp(),
          'name': avatar.name,
          'price': avatar.price,
        });
        
        // 3. Îl aplicăm opțional pe slotul dorit
        final field = applyToSlot == CarAvatarMapSlot.driver ? kFieldDriver : kFieldPassenger;
        transaction.set(_db.collection('users').doc(uid), {field: avatar.id}, SetOptions(merge: true));
        
        return true;
      });

      if (success) {
        _clearPurchasedAvatarCache();
        // Logăm tranzacția async pentru audit (fără a bloca UI-ul)
        unawaited(TokenService().logManualTransaction(
          uid: uid,
          amount: -avatar.price,
          type: TokenTransactionType.purchase,
          description: 'Cumpărare avatar: ${avatar.name}',
        ));
        
        Logger.info('Avatar cumpărat cu succes (Atomic): ${avatar.name}', tag: 'AVATAR_SHOP');
        return true;
      }
      return false;
    } catch (e, st) {
      Logger.error('Eroare la achiziția atomică în Galaxy Garage: $e', tag: 'AVATAR_SHOP', error: e, stackTrace: st);
      return false;
    }
  }

  /// Salvează avatarul pentru **un singur** mod (volan vs pasager).
  Future<bool> selectAvatarForSlot(String avatarId, CarAvatarMapSlot slot) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final avatar = getAvatarById(avatarId);
    if (slot == CarAvatarMapSlot.driver && !avatar.allowsDriverMapSlot) {
      Logger.warning(
        'Avatar ${avatar.id} nu e permis la volan (doar pasager).',
        tag: 'AVATAR_SHOP',
      );
      return false;
    }
    if (slot == CarAvatarMapSlot.passenger && !avatar.allowsPassengerMapSlot) {
      Logger.warning(
        'Avatar ${avatar.id} nu e permis ca pasager (ex. salupa doar la volan).',
        tag: 'AVATAR_SHOP',
      );
      return false;
    }

    final field = slot == CarAvatarMapSlot.driver ? kFieldDriver : kFieldPassenger;
    try {
      await _db.collection('users').doc(uid).set(
            {field: avatarId},
            SetOptions(merge: true),
          );
      Logger.info('Avatar selected ($slot): $avatarId', tag: 'AVATAR_SHOP');
      return true;
    } catch (e, st) {
      Logger.error(
        'selectAvatarForSlot failed: $e',
        tag: 'AVATAR_SHOP',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Setează același avatar pentru ambele moduri (ex. migrare / reset simplu).
  Future<bool> selectAvatarBothSlots(String avatarId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final avatar = getAvatarById(avatarId);
    final driverId = avatar.allowsDriverMapSlot ? avatarId : 'default_car';
    final passengerId = avatar.allowsPassengerMapSlot ? avatarId : 'default_car';
    try {
      await _db.collection('users').doc(uid).set(
            {kFieldDriver: driverId, kFieldPassenger: passengerId},
            SetOptions(merge: true),
          );
      return true;
    } catch (e, st) {
      Logger.error('selectAvatarBothSlots failed: $e',
          tag: 'AVATAR_SHOP', error: e, stackTrace: st);
      return false;
    }
  }

  CarAvatar getAvatarById(String id) {
    return _allAvatars.firstWhere((a) => a.id == id, orElse: () => CarAvatar.defaultCar());
  }

  /// ID din Firestore → ID sigur pentru slot șofer pe hartă / telemetry.
  static String coerceDriverAvatarIdForMap(String rawId) {
    final av = CarAvatarService().getAvatarById(rawId);
    return av.allowsDriverMapSlot ? rawId : 'default_car';
  }

  /// ID din Firestore → ID sigur pentru slot pasager pe hartă.
  static String coercePassengerAvatarIdForMap(String rawId) {
    final av = CarAvatarService().getAvatarById(rawId);
    return av.allowsPassengerMapSlot ? rawId : 'default_car';
  }
}

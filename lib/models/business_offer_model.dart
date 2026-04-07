import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/models/business_profile_model.dart';

class BusinessOffer {
  final String id;
  final String businessId;
  final String businessName;
  final BusinessCategory businessCategory;
  final double businessLatitude;
  final double businessLongitude;
  final String title;
  final String description;
  final String? link;
  final String? phone;
  final String? whatsapp;
  final bool isFlash;
  final int viewsCount;
  final DateTime createdAt;
  final bool isActive;

  /// Câte deschideri Mystery Box sunt alocate pentru ofertă (setat de comerciant). `null` sau `0` = nelimitat pe hartă (vechiul comportament).
  final int? mysteryBoxTotal;

  /// Câte deschideri s-au consumat deja (scriere atomică din Cloud Function).
  final int mysteryBoxClaimed;

  /// Câmp transient — calculat client-side, nu se stochează în Firestore.
  final double? distanceKm;

  const BusinessOffer({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessCategory,
    required this.businessLatitude,
    required this.businessLongitude,
    required this.title,
    required this.description,
    this.link,
    this.phone,
    this.whatsapp,
    this.isFlash = false,
    this.viewsCount = 0,
    required this.createdAt,
    this.isActive = true,
    this.mysteryBoxTotal,
    this.mysteryBoxClaimed = 0,
    this.distanceKm,
  });

  /// Câte cutii mai pot fi deschise; `null` dacă nu e cap limitat.
  int? get mysteryBoxRemaining {
    final t = mysteryBoxTotal;
    if (t == null || t <= 0) return null;
    return (t - mysteryBoxClaimed).clamp(0, t);
  }

  bool get mysteryBoxExhausted {
    final t = mysteryBoxTotal;
    if (t == null || t <= 0) return false;
    return mysteryBoxClaimed >= t;
  }

  BusinessOffer withDistance(double km) => BusinessOffer(
        id: id,
        businessId: businessId,
        businessName: businessName,
        businessCategory: businessCategory,
        businessLatitude: businessLatitude,
        businessLongitude: businessLongitude,
        title: title,
        description: description,
        link: link,
        phone: phone,
        whatsapp: whatsapp,
        isFlash: isFlash,
        viewsCount: viewsCount,
        createdAt: createdAt,
        isActive: isActive,
        mysteryBoxTotal: mysteryBoxTotal,
        mysteryBoxClaimed: mysteryBoxClaimed,
        distanceKm: km,
      );

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'businessName': businessName,
        'businessCategory': businessCategory.name,
        'businessLatitude': businessLatitude,
        'businessLongitude': businessLongitude,
        'title': title,
        'description': description,
        'link': link,
        'phone': phone,
        'whatsapp': whatsapp,
        'isFlash': isFlash,
        'viewsCount': viewsCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
        if (mysteryBoxTotal != null && mysteryBoxTotal! > 0)
          'mysteryBoxTotal': mysteryBoxTotal,
        'mysteryBoxClaimed': mysteryBoxClaimed,
      };

  factory BusinessOffer.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BusinessOffer(
      id: doc.id,
      businessId: d['businessId'] ?? '',
      businessName: d['businessName'] ?? '',
      businessCategory: BusinessCategory.values.firstWhere(
        (e) => e.name == (d['businessCategory'] ?? 'altele'),
        orElse: () => BusinessCategory.altele,
      ),
      businessLatitude: (d['businessLatitude'] as num?)?.toDouble() ?? 0.0,
      businessLongitude: (d['businessLongitude'] as num?)?.toDouble() ?? 0.0,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      link: d['link'],
      phone: d['phone'],
      whatsapp: d['whatsapp'],
      isFlash: d['isFlash'] ?? false,
      viewsCount: (d['viewsCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] ?? true,
      mysteryBoxTotal: () {
        final v = d['mysteryBoxTotal'];
        if (v is num) {
          final i = v.toInt();
          return i > 0 ? i : null;
        }
        return null;
      }(),
      mysteryBoxClaimed: (d['mysteryBoxClaimed'] as num?)?.toInt() ?? 0,
    );
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stochează local (SharedPreferences) ofertele și comercianții ascunși de user.
class OfferPreferencesService {
  static final OfferPreferencesService _instance = OfferPreferencesService._();
  factory OfferPreferencesService() => _instance;
  OfferPreferencesService._();

  static const _keyOfferIds    = 'hidden_offer_ids';
  static const _keyOfferTitles = 'hidden_offer_titles';
  static const _keyBizIds      = 'hidden_business_ids';
  static const _keyBizNames    = 'hidden_business_names';

  Set<String> _hiddenOfferIds = {};
  Map<String, String> _hiddenOfferTitles = {};   // offerId → title
  Set<String> _hiddenBizIds = {};
  Map<String, String> _hiddenBizNames = {};      // businessId → businessName

  // ── Getteri ──────────────────────────────────────────────────────────────────

  bool get hasHidden => _hiddenOfferIds.isNotEmpty || _hiddenBizIds.isNotEmpty;
  int  get hiddenCount => _hiddenOfferIds.length + _hiddenBizIds.length;

  Set<String>         get hiddenOfferIds   => Set.unmodifiable(_hiddenOfferIds);
  Map<String, String> get hiddenOfferTitles => Map.unmodifiable(_hiddenOfferTitles);
  Set<String>         get hiddenBizIds     => Set.unmodifiable(_hiddenBizIds);
  Map<String, String> get hiddenBizNames   => Map.unmodifiable(_hiddenBizNames);

  bool isOfferHidden(String id)    => _hiddenOfferIds.contains(id);
  bool isBusinessHidden(String id) => _hiddenBizIds.contains(id);

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hiddenOfferIds = Set<String>.from(prefs.getStringList(_keyOfferIds) ?? []);
    _hiddenBizIds   = Set<String>.from(prefs.getStringList(_keyBizIds)   ?? []);

    final offerTitlesJson = prefs.getString(_keyOfferTitles);
    if (offerTitlesJson != null) {
      _hiddenOfferTitles = Map<String, String>.from(jsonDecode(offerTitlesJson));
    }
    final bizNamesJson = prefs.getString(_keyBizNames);
    if (bizNamesJson != null) {
      _hiddenBizNames = Map<String, String>.from(jsonDecode(bizNamesJson));
    }
  }

  // ── Ascunde ───────────────────────────────────────────────────────────────────

  Future<void> hideOffer(String offerId, String title) async {
    _hiddenOfferIds.add(offerId);
    _hiddenOfferTitles[offerId] = title;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyOfferIds, _hiddenOfferIds.toList());
    await prefs.setString(_keyOfferTitles, jsonEncode(_hiddenOfferTitles));
  }

  Future<void> hideBusiness(String businessId, String businessName) async {
    _hiddenBizIds.add(businessId);
    _hiddenBizNames[businessId] = businessName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyBizIds, _hiddenBizIds.toList());
    await prefs.setString(_keyBizNames, jsonEncode(_hiddenBizNames));
  }

  // ── Restaurează ───────────────────────────────────────────────────────────────

  Future<void> unhideOffer(String offerId) async {
    _hiddenOfferIds.remove(offerId);
    _hiddenOfferTitles.remove(offerId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyOfferIds, _hiddenOfferIds.toList());
    await prefs.setString(_keyOfferTitles, jsonEncode(_hiddenOfferTitles));
  }

  Future<void> unhideBusiness(String businessId) async {
    _hiddenBizIds.remove(businessId);
    _hiddenBizNames.remove(businessId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyBizIds, _hiddenBizIds.toList());
    await prefs.setString(_keyBizNames, jsonEncode(_hiddenBizNames));
  }

  Future<void> clearAll() async {
    _hiddenOfferIds.clear();
    _hiddenOfferTitles.clear();
    _hiddenBizIds.clear();
    _hiddenBizNames.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOfferIds);
    await prefs.remove(_keyOfferTitles);
    await prefs.remove(_keyBizIds);
    await prefs.remove(_keyBizNames);
  }
}

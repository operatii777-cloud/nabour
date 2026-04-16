import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';

/// Mod comunitate / școală (Bump-style): etichetă opțională în profil + filtre sociale viitoare.
class CommunityModeService {
  CommunityModeService._();
  static final CommunityModeService instance = CommunityModeService._();

  static const _kMode = 'community_mode';
  static const _kSchool = 'community_school_label';

  String _mode = 'none';
  String _schoolLabel = '';
  bool _loaded = false;

  String get mode => _loaded ? _mode : 'none';
  String get schoolLabel => _schoolLabel;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _mode = p.getString(_kMode) ?? 'none';
    _schoolLabel = p.getString(_kSchool) ?? '';
    _loaded = true;
  }

  Future<void> setModeAndSchool({
    required String mode,
    required String schoolLabel,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMode, mode);
    await p.setString(_kSchool, schoolLabel);
    _mode = mode;
    _schoolLabel = schoolLabel;
    _loaded = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'communityMode': mode,
        'schoolLabel': schoolLabel.trim(),
        'communityUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      Logger.warning('CommunityModeService.setModeAndSchool Firestore sync failed: $e', tag: 'COMMUNITY');
    }
  }
}

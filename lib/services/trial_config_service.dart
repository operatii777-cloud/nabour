import 'package:cloud_firestore/cloud_firestore.dart';

/// Excepții trial: document `app_config/trial` cu `exemptEmails` / `exemptUids` (array).
/// Configurezi din Firebase Console; fără hardcodare în cod.
class TrialConfigService {
  TrialConfigService._();
  static final TrialConfigService instance = TrialConfigService._();

  static const _docPath = 'app_config/trial';

  Future<bool> isExempt({String? uid, String? email}) async {
    final e = email?.toLowerCase().trim();
    if ((uid == null || uid.isEmpty) && (e == null || e.isEmpty)) return false;
    try {
      final snap = await FirebaseFirestore.instance.doc(_docPath).get();
      if (!snap.exists) return false;
      final d = snap.data() ?? {};
      final emails = (d['exemptEmails'] as List<dynamic>?)?.map((x) => '$x'.toLowerCase().trim()).toList() ?? [];
      final uids = (d['exemptUids'] as List<dynamic>?)?.map((x) => '$x').toList() ?? [];
      if (e != null && emails.contains(e)) return true;
      if (uid != null && uid.isNotEmpty && uids.contains(uid)) return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}

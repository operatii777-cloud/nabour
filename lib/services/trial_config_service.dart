import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:nabour_app/services/nabour_functions.dart';
import 'package:nabour_app/utils/logger.dart';

/// Excepții trial: document `app_config/trial` cu `exemptEmails` / `exemptUids` (array).
/// Configurezi din Firebase Console; fără hardcodare în cod.
///
/// Ancla server (`users/{uid}.trialEndsAt`) este scrisă de Cloud Function
/// [nabourEnsureUserTrialAnchor] — necesară ca regulile Firestore să permită curse.
class TrialConfigService {
  TrialConfigService._();
  static final TrialConfigService instance = TrialConfigService._();

  static const _docPath = 'app_config/trial';

  /// Apel silențios la login: propagă din Auth metadata → Firestore pentru reguli.
  Future<void> ensureTrialAnchorFromServer() async {
    try {
      await NabourFunctions.instance
          .httpsCallable('nabourEnsureUserTrialAnchor')
          .call();
    } on FirebaseFunctionsException catch (_) {
      // Fără log zgomot: funcția poate lipsi înainte de deploy sau offline.
    } catch (e) {
      Logger.warning('ensureTrialAnchorFromServer unexpected error: $e', tag: 'TRIAL');
    }
  }

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
    } catch (err) {
      Logger.warning('isExempt Firestore read failed: $err', tag: 'TRIAL');
      return false;
    }
  }
}

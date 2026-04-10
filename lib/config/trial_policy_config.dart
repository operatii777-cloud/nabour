import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:nabour_app/utils/logger.dart';

/// Politica trial: lista de emailuri scutite de ecranul „trial expirat”.
///
/// Firebase Remote Config — cheie **String**: [keyExemptEmails]
/// Format: `email1@x.com,email2@y.com` (virgulă, fără spații obligatorii).
/// Dacă parametrul lipsește sau e gol după parse, se folosește lista integrată
/// [_builtinEmails] din app (fallback).
class TrialPolicyConfig extends ChangeNotifier {
  TrialPolicyConfig._();
  static final TrialPolicyConfig instance = TrialPolicyConfig._();

  static const String keyExemptEmails = 'trial_exempt_emails';

  /// Fallback dacă Remote Config nu e disponibil sau returnează nimic valid.
  static const List<String> _builtinEmails = [
    'operatii.777@gmail.com',
    'operatii.77@gmail.com',
    'operatii.77777@gmail.com',
  ];

  static String get _builtinCsv => _builtinEmails.join(',');

  List<String> _exemptLowercase = _parseExemptCsv(_builtinCsv);

  /// Email deja normalizat: `toLowerCase().trim()`.
  bool isExempt(String emailLowercaseTrimmed) =>
      _exemptLowercase.contains(emailLowercaseTrimmed);

  static List<String> _parseExemptCsv(String csv) {
    return csv
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.contains('@'))
        .toList(growable: false);
  }

  /// Aceeași logică ca la Remote Config — folosit în teste.
  static List<String> parseExemptEmailList(String csv) => _parseExemptCsv(csv);

  /// Apelat după [Firebase.initializeApp]. Nu aruncă; la succes notifică ascultători (UI trial).
  Future<void> refreshFromRemote() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.ensureInitialized();

      await rc.setDefaults(<String, dynamic>{
        keyExemptEmails: _builtinCsv,
      });

      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 12),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 1),
        ),
      );

      _apply(rc);
      try {
        await rc.fetchAndActivate();
      } catch (e, st) {
        Logger.warning(
          'TrialPolicyConfig: fetchAndActivate failed, using activated defaults: $e\n$st',
          tag: 'RC',
        );
      }
      _apply(rc);
    } catch (e, st) {
      Logger.warning(
        'TrialPolicyConfig: init failed, using builtin list: $e\n$st',
        tag: 'RC',
      );
      _exemptLowercase = _parseExemptCsv(_builtinCsv);
    }
    notifyListeners();
  }

  void _apply(FirebaseRemoteConfig rc) {
    final remoteCsv = rc.getString(keyExemptEmails);
    final remoteList = _parseExemptCsv(remoteCsv);
    final builtinList = _parseExemptCsv(_builtinCsv);

    // Combinăm listele (set pentru unicitate) astfel încât admin-ul să fie mereu scutit
    _exemptLowercase = {
      ...remoteList,
      ...builtinList,
    }.toList();

    Logger.debug(
      'TrialPolicyConfig: Applied ${_exemptLowercase.length} exempt emails '
      '(Remote: ${remoteList.length}, Builtin: ${builtinList.length})',
      tag: 'RC',
    );
  }
}

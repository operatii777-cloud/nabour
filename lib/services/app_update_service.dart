import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:nabour_app/utils/logger.dart';

/// Informații despre o versiune disponibilă.
class AppUpdateInfo {
  final String latestVersion;    // ex: "1.2.0"
  final int latestBuildNumber;   // ex: 12
  final String apkUrl;           // URL Firebase Storage / CDN
  final String changelog;        // Ce e nou în această versiune
  final bool forceUpdate;        // Dacă update-ul este obligatoriu

  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.apkUrl,
    required this.changelog,
    this.forceUpdate = false,
  });

  factory AppUpdateInfo.fromFirestore(Map<String, dynamic> data) {
    return AppUpdateInfo(
      latestVersion: data['latestVersion'] as String? ?? '1.0.0',
      latestBuildNumber: (data['latestBuildNumber'] as num?)?.toInt() ?? 1,
      apkUrl: data['apkUrl'] as String? ?? '',
      changelog: data['changelog'] as String? ?? 'Îmbunătățiri și corecturi.',
      forceUpdate: data['forceUpdate'] as bool? ?? false,
    );
  }
}

/// Starea unui download în desfășurare.
enum UpdateDownloadState { idle, downloading, installing, error }

class AppUpdateService extends ChangeNotifier {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

  // ── State ─────────────────────────────────────────────────────────────────

  AppUpdateInfo? _updateInfo;
  bool _updateAvailable = false;
  UpdateDownloadState _downloadState = UpdateDownloadState.idle;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  String _currentVersion = '1.0.0';
  int _currentBuildNumber = 1;

  AppUpdateInfo? get updateInfo => _updateInfo;
  bool get updateAvailable => _updateAvailable;
  UpdateDownloadState get downloadState => _downloadState;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  String get currentVersion => _currentVersion;

  // ── Verificare versiune ───────────────────────────────────────────────────

  /// Verifică dacă există o versiune mai nouă în Firestore.
  /// Documentul urmărit: `app_config/android_update`
  Future<void> checkForUpdate() async {
    // Dezactivat temporar — aplicația nu este încă publicată în Firebase Console.
    return;
    // ignore: dead_code
    try {
      // 1. Versiunea curentă a aplicației instalate
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
      _currentBuildNumber = int.tryParse(info.buildNumber) ?? 1;

      // 2. Date din Firestore
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('android_update')
          .get();

      if (!doc.exists || doc.data() == null) return;

      final updateInfo = AppUpdateInfo.fromFirestore(doc.data()!);

      // 3. Comparăm build numbers (mai simplu și mai sigur decât string version)
      if (updateInfo.latestBuildNumber > _currentBuildNumber) {
        _updateInfo = updateInfo;
        _updateAvailable = true;
        Logger.info(
          'Update disponibil: v${updateInfo.latestVersion}+${updateInfo.latestBuildNumber} '
          '(curent: v$_currentVersion+$_currentBuildNumber)',
          tag: 'AppUpdateService',
        );
      } else {
        _updateAvailable = false;
        _updateInfo = null;
      }
      notifyListeners();
    } catch (e) {
      Logger.error('checkForUpdate error', error: e, tag: 'AppUpdateService');
    }
  }

  // ── Download & Install ────────────────────────────────────────────────────

  /// Descarcă APK-ul și lansează instalarea.
  Future<void> downloadAndInstall() async {
    final info = _updateInfo;
    if (info == null || info.apkUrl.isEmpty) return;

    // Android only — iOS instalează prin App Store
    if (!Platform.isAndroid) return;

    _downloadState = UpdateDownloadState.downloading;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // Director temp
      final tempDir = await getTemporaryDirectory();
      final apkPath = '${tempDir.path}/nabour_update_${info.latestBuildNumber}.apk';

      // Download cu progres
      final dio = Dio();
      await dio.download(
        info.apkUrl,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );

      _downloadState = UpdateDownloadState.installing;
      notifyListeners();

      // Lansează instalarea APK
      final result = await OpenFile.open(apkPath, type: 'application/vnd.android.package-archive');
      Logger.info('OpenFile result: ${result.message}', tag: 'AppUpdateService');

      // Resetăm la idle după ce se deschide instalatorul
      _downloadState = UpdateDownloadState.idle;
      notifyListeners();
    } catch (e) {
      Logger.error('downloadAndInstall error', error: e, tag: 'AppUpdateService');
      _downloadState = UpdateDownloadState.error;
      _errorMessage = 'Eroare la descărcare: $e';
      notifyListeners();
    }
  }

  /// Resetează starea de eroare.
  void resetError() {
    _downloadState = UpdateDownloadState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}

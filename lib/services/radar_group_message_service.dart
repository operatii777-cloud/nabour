import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/services/nabour_functions.dart';
import 'package:nabour_app/utils/content_filter.dart';
import 'package:nabour_app/utils/logger.dart';

/// Trimite un mesaj text către vecinii capturați în radar (FCM prin Cloud Function).
class RadarGroupMessageService {
  Future<RadarGroupSendResult> send({
    required List<String> recipientUids,
    required String message,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const RadarGroupSendResult(
        success: false,
        error: 'Trebuie să fii autentificat.',
      );
    }
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const RadarGroupSendResult(
        success: false,
        error: 'Scrie un mesaj.',
      );
    }
    final filter = ContentFilter.check(trimmed);
    if (!filter.isClean) {
      return RadarGroupSendResult(
        success: false,
        error: filter.message ?? 'Mesaj inadecvat.',
      );
    }
    final unique = recipientUids.toSet().where((u) => u.isNotEmpty && u != uid).toList();
    if (unique.isEmpty) {
      return const RadarGroupSendResult(
        success: false,
        error: 'Nu există destinatari valizi.',
      );
    }
    try {
      final res = await NabourFunctions.instance
          .httpsCallable('nabourSendRadarGroupMessage')
          .call({
        'recipientUids': unique,
        'message': trimmed,
      });
      final map = res.data as Map<Object?, Object?>?;
      final sent = (map?['sent'] as num?)?.toInt() ?? 0;
      final attempted = (map?['attempted'] as num?)?.toInt() ?? unique.length;
      return RadarGroupSendResult(
        success: true,
        sent: sent,
        attempted: attempted,
      );
    } on FirebaseFunctionsException catch (e) {
      Logger.warning(
        'nabourSendRadarGroupMessage: ${e.code} ${e.message}',
        tag: 'RADAR_MSG',
      );
      return RadarGroupSendResult(
        success: false,
        error: e.message ?? e.code,
      );
    } catch (e) {
      Logger.error('Radar group send: $e', error: e, tag: 'RADAR_MSG');
      return RadarGroupSendResult(success: false, error: '$e');
    }
  }
}

class RadarGroupSendResult {
  final bool success;
  final String? error;
  final int sent;
  final int attempted;

  const RadarGroupSendResult({
    required this.success,
    this.error,
    this.sent = 0,
    this.attempted = 0,
  });
}

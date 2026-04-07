import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

/// Serviciu pentru partajarea traseului live cu contacte de încredere.
/// Creează un document Firestore public (/safe_rides/{token}) cu locația în timp real.
/// Link-ul poate fi deschis în browser fără autentificare.
class SafeRideService {
  static final SafeRideService _instance = SafeRideService._();
  factory SafeRideService() => _instance;
  SafeRideService._();

  static const String _tag = 'SAFE_RIDE';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _activeToken;

  /// Creează un token de urmărire pentru cursa curentă.
  /// Returnează URL-ul de partajat.
  Future<String> createTrackingLink({
    required String rideId,
    required String passengerName,
    required String destinationAddress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final token = const Uuid().v4();
    _activeToken = token;

    await _db.collection('safe_rides').doc(token).set({
      'createdByUid': uid,
      'rideId': rideId,
      'passengerName': passengerName,
      'destinationAddress': destinationAddress,
      'passengerLat': null,
      'passengerLng': null,
      'driverLat': null,
      'driverLng': null,
      'etaMinutes': null,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 3))),
    });

    final url = 'https://friendsride.app/track/$token';
    Logger.info('Safe ride link created: $url', tag: _tag);
    return url;
  }

  /// Actualizează locația în timp real în documentul de urmărire.
  Future<void> updateLocation({
    required double driverLat,
    required double driverLng,
    required int etaMinutes,
  }) async {
    if (_activeToken == null) return;
    try {
      await _db.collection('safe_rides').doc(_activeToken!).update({
        'driverLat': driverLat,
        'driverLng': driverLng,
        'etaMinutes': etaMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.debug('Safe ride location update failed: $e', tag: _tag);
    }
  }

  /// Marchează cursa ca finalizată și dezactivează link-ul.
  Future<void> endTracking() async {
    if (_activeToken == null) return;
    try {
      await _db.collection('safe_rides').doc(_activeToken!).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      _activeToken = null;
    } catch (e) {
      Logger.debug('Safe ride end tracking failed: $e', tag: _tag);
    }
  }

  /// Partajează link-ul via share sheet nativ.
  Future<void> shareLink(String url, String passengerName) async {
    await SharePlus.instance.share(
      ShareParams(
        text: '🚗 Urmărește călătoria lui $passengerName live:\n$url\n\nPowered by Nabour',
        subject: 'Urmărire cursă Nabour',
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// RTDB / exporturi pot folosi tipuri non-bool pentru flag-uri.
bool neighborBool(dynamic v, {bool ifNull = false}) {
  if (v == null) return ifNull;
  if (v == true) return true;
  if (v == false) return false;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == 'false' || s == '0' || s == 'no' || s.isEmpty) return false;
    if (s == 'true' || s == '1' || s == 'yes') return true;
    return false;
  }
  return false;
}

/// Date ale unui vecin vizibil pe hartă (Firestore sau RTDB).
class NeighborLocation {
  final String uid;
  final double lat;
  final double lng;
  final String avatar;
  final String displayName;
  final DateTime lastUpdate;
  final bool isDriver;
  final String? licensePlate;
  final String? activityStatus; // e.g. 'driving', 'active', 'sos', 'away'
  final bool isOnline;
  final bool isPulsing;
  /// Viteză raportată (m/s), ex. din RTDB `speed`.
  final double? speedMps;
  /// Procent baterie 0–100, ex. din RTDB `battery`.
  final int? batteryLevel;
  final bool isCharging;
  /// `home` | `work` | `school` din adrese salvate + proximitate.
  final String? placeKind;
  /// Epocă locală ms — când a început staționarea (clientul emitent).
  final int? stationarySinceMs;
  /// URL poză de profil (pentru marker pe hartă).
  final String? photoURL;

  /// ID avatar Galaxy Garage (`users.selectedCarAvatarId`) — același bundle PNG pe toate device-urile.
  final String? carAvatarId;

  const NeighborLocation({
    required this.uid,
    required this.lat,
    required this.lng,
    required this.avatar,
    required this.displayName,
    required this.lastUpdate,
    this.isDriver = false,
    this.licensePlate,
    this.activityStatus,
    this.isOnline = true,
    this.isPulsing = false,
    this.speedMps,
    this.batteryLevel,
    this.isCharging = false,
    this.placeKind,
    this.stationarySinceMs,
    this.photoURL,
    this.carAvatarId,
  });

  factory NeighborLocation.fromMap(String uid, Map<String, dynamic> m) =>
      NeighborLocation(
        uid: uid,
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0,
        avatar: m['avatar'] as String? ?? '🙂',
        displayName: m['displayName'] as String? ?? 'Vecin',
        lastUpdate: (m['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isDriver: neighborBool(m['isDriver']),
        licensePlate: (m['licensePlate'] as String?)?.isNotEmpty == true
            ? m['licensePlate'] as String
            : null,
        activityStatus: m['activityStatus'] as String?,
        isOnline: neighborBool(m['isOnline'], ifNull: true),
        isPulsing: neighborBool(m['isPulsing']),
        speedMps: (m['speed'] as num?)?.toDouble(),
        batteryLevel: (m['battery'] as num?)?.toInt(),
        isCharging: neighborBool(m['charging']),
        placeKind: m['placeKind'] as String?,
        stationarySinceMs: (m['stationarySince'] as num?)?.toInt(),
        photoURL: m['photoURL'] as String?,
        carAvatarId: m['carAvatarId'] as String?,
      );

  /// Snapshot RTDB `/telemetry/locations/{h3}/{uid}` ([updatedAt] server millis).
  factory NeighborLocation.fromRtdb(String uid, Map<Object?, Object?> raw) {
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final lat = (m['lat'] as num?)?.toDouble() ?? 0;
    final lng = (m['lng'] as num?)?.toDouble() ?? 0;
    final updatedAt = m['updatedAt'];
    DateTime lastUpdate = DateTime.now();
    if (updatedAt is int) {
      lastUpdate = DateTime.fromMillisecondsSinceEpoch(updatedAt);
    }
    final plate = m['licensePlate'] as String?;
    return NeighborLocation(
      uid: uid,
      lat: lat,
      lng: lng,
      avatar: m['avatar'] as String? ?? '🙂',
      displayName: m['displayName'] as String? ?? 'Vecin',
      lastUpdate: lastUpdate,
      isDriver: neighborBool(m['isDriver']),
      licensePlate: plate != null && plate.isNotEmpty ? plate : null,
      activityStatus: m['activityStatus'] as String?,
      isOnline: neighborBool(m['isOnline'], ifNull: true),
      isPulsing: neighborBool(m['isPulsing']),
      speedMps: (m['speed'] as num?)?.toDouble(),
      batteryLevel: (m['battery'] as num?)?.toInt(),
      isCharging: neighborBool(m['charging']),
      placeKind: m['placeKind'] as String?,
      stationarySinceMs: (m['stationarySince'] as num?)?.toInt(),
      photoURL: m['photoURL'] as String?,
      carAvatarId: m['carAvatarId'] as String?,
    );
  }
}

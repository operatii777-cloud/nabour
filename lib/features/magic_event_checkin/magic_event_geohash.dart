import 'dart:math' as math;

/// Geohash for Firestore whereIn queries on events (same idea as driver_locations).
class MagicEventGeohash {
  MagicEventGeohash._();

  static const double earthRadiusM = 6371000;
  static const int precision = 6;

  static String encode(double lat, double lng) {
    const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    const int bits = 5;

    double minLat = -90.0;
    double maxLat = 90.0;
    double minLng = -180.0;
    double maxLng = 180.0;

    String geohash = '';
    int bit = 0;
    int ch = 0;

    while (geohash.length < precision) {
      if (bit % 2 == 0) {
        final double mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          ch |= (1 << (4 - bit % bits));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final double mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= (1 << (4 - bit % bits));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      bit++;
      if (bit % bits == 0) {
        geohash += base32[ch];
        ch = 0;
      }
    }

    return geohash;
  }

  static List<String> nearbyGeohashes(double lat, double lng, double radiusKm) {
    final hashes = <String>{encode(lat, lng)};
    final radiusM = radiusKm * 1000;
    final latDelta = radiusM / earthRadiusM * (180 / math.pi);
    final lngDelta =
        radiusM / (earthRadiusM * math.cos(lat * math.pi / 180)) * (180 / math.pi);

    for (double dLat = -latDelta; dLat <= latDelta; dLat += latDelta / 2) {
      for (double dLng = -lngDelta; dLng <= lngDelta; dLng += lngDelta / 2) {
        if (dLat == 0 && dLng == 0) continue;
        final nLat = lat + dLat;
        final nLng = lng + dLng;
        if (nLat >= -90 && nLat <= 90 && nLng >= -180 && nLng <= 180) {
          hashes.add(encode(nLat, nLng));
        }
      }
    }
    return hashes.toList();
  }
}

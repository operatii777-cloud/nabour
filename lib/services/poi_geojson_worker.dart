import 'dart:convert';

/// Top-level entry for [compute] — keeps JSON decode + thousands of features off the UI isolate.
List<Map<String, dynamic>> parseLocalGeoJsonForWorker(String content) {
  final data = json.decode(content) as Map<String, dynamic>;
  final features = (data['features'] as List?) ?? const [];
  final out = <Map<String, dynamic>>[];
  var index = 0;
  for (final f in features) {
    index++;
    if (f is! Map<String, dynamic>) continue;
    final props = (f['properties'] as Map<String, dynamic>?) ?? {};
    final geom = (f['geometry'] as Map<String, dynamic>?) ?? {};
    final type = (geom['type'] as String? ?? '').toLowerCase();

    double? lat;
    double? lng;

    if (type == 'point') {
      final coords = (geom['coordinates'] as List?) ?? const [];
      if (coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    } else if (type == 'polygon') {
      final coords = (geom['coordinates'] as List?) ?? const [];
      final centroid = _centroidFromPolygon(coords);
      if (centroid != null) {
        lat = centroid[0];
        lng = centroid[1];
      }
    } else if (type == 'multipolygon') {
      final coords = (geom['coordinates'] as List?) ?? const [];
      final centroid = _centroidFromMultiPolygon(coords);
      if (centroid != null) {
        lat = centroid[0];
        lng = centroid[1];
      }
    }

    if (lat == null || lng == null) continue;

    final name = (props['name'] as String?)?.trim();
    final amenity = (props['amenity'] as String?)?.toLowerCase();
    final tourism = (props['tourism'] as String?)?.toLowerCase();
    final shop = (props['shop'] as String?)?.toLowerCase();
    final categoryName = _mapOsmToCategoryName(amenity: amenity, tourism: tourism, shop: shop);

    final addrStreet = props['addr:street']?.toString();
    final addrNumber = props['addr:housenumber']?.toString();
    final addrCity = props['addr:city']?.toString();
    final brand = props['brand']?.toString();
    final operatorName = props['operator']?.toString();

    final additionalInfo = <String, dynamic>{
      if (amenity != null) 'amenity': amenity,
      if (tourism != null) 'tourism': tourism,
      if (shop != null) 'shop': shop,
      'phone': props['phone'],
      'website': props['website'],
      'opening_hours': props['opening_hours'],
      if (addrStreet != null) 'addr:street': addrStreet,
      if (addrNumber != null) 'addr:housenumber': addrNumber,
      if (addrCity != null) 'addr:city': addrCity,
      if (brand != null) 'brand': brand,
      if (operatorName != null) 'operator': operatorName,
    };

    out.add({
      'id': f['id']?.toString() ?? 'local_geojson_${index}_$categoryName',
      'name': name == null || name.isEmpty ? 'POI' : name,
      'description':
          (props['address'] ?? props['addr:full'] ?? props['opening_hours'] ?? '').toString(),
      'lat': lat,
      'lng': lng,
      'categoryName': categoryName,
      'additionalInfo': additionalInfo,
    });
  }
  return out;
}

List<double>? _centroidFromPolygon(List<dynamic> polygonCoords) {
  if (polygonCoords.isEmpty) return null;
  final outer = (polygonCoords.first as List?) ?? const [];
  if (outer.isEmpty) return null;
  return _computeCentroidFromLngLatList(outer.cast<List>());
}

List<double>? _centroidFromMultiPolygon(List<dynamic> multiPolygonCoords) {
  if (multiPolygonCoords.isEmpty) return null;
  final List<List> allPoints = [];
  for (final poly in multiPolygonCoords) {
    final polygon = (poly as List?) ?? const [];
    if (polygon.isEmpty) continue;
    final outer = (polygon.first as List?) ?? const [];
    if (outer.isEmpty) continue;
    allPoints.addAll(outer.cast<List>());
  }
  if (allPoints.isEmpty) return null;
  return _computeCentroidFromLngLatList(allPoints);
}

List<double>? _computeCentroidFromLngLatList(List<List> lngLatPairs) {
  double sumLat = 0.0;
  double sumLng = 0.0;
  var count = 0;
  for (final pair in lngLatPairs) {
    if (pair.length < 2) continue;
    final lng = (pair[0] as num).toDouble();
    final lat = (pair[1] as num).toDouble();
    sumLat += lat;
    sumLng += lng;
    count++;
  }
  if (count == 0) return null;
  return [sumLat / count, sumLng / count];
}

String _mapOsmToCategoryName({String? amenity, String? tourism, String? shop}) {
  final a = (amenity ?? '').toLowerCase();
  final t = (tourism ?? '').toLowerCase();
  final s = (shop ?? '').toLowerCase();

  if (a == 'fuel') return 'gasStation';
  if (a == 'restaurant' || a == 'fast_food' || a == 'cafe' || a == 'food_court') return 'restaurant';
  if (a == 'parking' || a == 'parking_entrance' || a == 'parking_space') return 'parking';
  if (a == 'hospital' || a == 'clinic') return 'hospital';
  if (a == 'pharmacy') return 'pharmacy';
  if (a == 'hotel' || t == 'hotel' || s == 'hotel') return 'hotel';
  if (s == 'supermarket' || s == 'grocery' || s == 'convenience') return 'supermarket';
  if (a == 'bank') return 'bank';
  if (a == 'atm') return 'atm';
  if (a == 'school' || a == 'kindergarten') return 'school';
  if (a == 'university' || a == 'college') return 'university';
  if (a == 'library') return 'library';
  if (a == 'police') return 'police';
  if (a == 'post_office') return 'postOffice';
  if (a == 'shopping_mall' || a == 'mall' || a == 'marketplace') return 'mall';
  if (s == 'bakery' || a == 'bakery') return 'bakery';
  if (a == 'bar' || a == 'pub') return 'barPub';
  if (a == 'park') return 'park';
  if (a == 'museum') return 'museum';
  if (a == 'cinema') return 'cinema';
  if (a == 'theatre') return 'theatre';
  if (a == 'playground') return 'playground';
  if (a == 'charging_station') return 'chargingStation';
  if (a == 'car_wash') return 'carWash';
  if (a == 'car_repair') return 'carRepair';
  if (a == 'bus_stop' ||
      a == 'tram_stop' ||
      a == 'train_station' ||
      a == 'subway_entrance' ||
      a == 'public_transport') {
    return 'publicTransport';
  }
  if (a == 'aerodrome' || a == 'airport') return 'airport';
  if (t.isNotEmpty) return 'tourism';
  return 'other';
}

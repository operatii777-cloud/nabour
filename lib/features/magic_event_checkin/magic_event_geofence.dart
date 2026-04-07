import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_model.dart';

bool magicEventIsActiveAt(MagicEvent event, DateTime now) {
  return !now.isBefore(event.startAt) && !now.isAfter(event.endAt);
}

double magicEventDistanceToCenterMeters({
  required double userLat,
  required double userLng,
  required MagicEvent event,
}) {
  return Geolocator.distanceBetween(
    userLat,
    userLng,
    event.latitude,
    event.longitude,
  );
}

bool magicEventUserIsInside({
  required double userLat,
  required double userLng,
  required MagicEvent event,
}) {
  return magicEventDistanceToCenterMeters(
        userLat: userLat,
        userLng: userLng,
        event: event,
      ) <=
      event.radiusMeters;
}

List<MagicEvent> magicEventsUserIsInsideNow({
  required double userLat,
  required double userLng,
  required Iterable<MagicEvent> candidates,
  DateTime? now,
}) {
  final t = now ?? DateTime.now();
  final out = <MagicEvent>[];
  for (final e in candidates) {
    if (!magicEventIsActiveAt(e, t)) continue;
    if (magicEventUserIsInside(userLat: userLat, userLng: userLng, event: e)) {
      out.add(e);
    }
  }
  return out;
}

import 'package:nabour_app/features/activity_feed/activity_feed_service.dart';

/// High-level helpers for posting common activity events.
class ActivityFeedWriter {
  ActivityFeedWriter._();

  static Future<void> leftPlace(String placeName, {double? lat, double? lng}) =>
      ActivityFeedService.instance.postEvent(
        type: 'left_place',
        text: 'a plecat de la $placeName',
        lat: lat,
        lng: lng,
      );

  static Future<void> arrivedAtPlace(String placeName,
          {double? lat, double? lng}) =>
      ActivityFeedService.instance.postEvent(
        type: 'arrived_place',
        text: 'a ajuns la $placeName',
        lat: lat,
        lng: lng,
      );

  static Future<void> startedDriving({double? lat, double? lng}) =>
      ActivityFeedService.instance.postEvent(
        type: 'started_driving',
        text: 'a plecat cu mașina',
        lat: lat,
        lng: lng,
      );

  static Future<void> postedMoment(String caption, {double? lat, double? lng}) =>
      ActivityFeedService.instance.postEvent(
        type: 'moment',
        text: caption,
        lat: lat,
        lng: lng,
      );

  /// Proximitate / „Hit” pe hartă — `type` în Firestore este `hit` (nu mai folosim `bump`).
  static Future<void> hitWith(String friendName) =>
      ActivityFeedService.instance.postEvent(
        type: 'hit',
        text: 's-a întâlnit cu $friendName',
      );

  /// Ai ajuns în raza unei Mystery Box (apare în meniul Activitate pentru tine).
  static Future<void> mysteryBoxNearby(String businessName,
          {double? lat, double? lng}) =>
      ActivityFeedService.instance.postEvent(
        type: 'mystery_nearby',
        text: 'e lângă Mystery Box ($businessName)',
        lat: lat,
        lng: lng,
      );

  static Future<void> mysteryBoxOpened(String businessName,
          {double? lat, double? lng}) =>
      ActivityFeedService.instance.postEvent(
        type: 'mystery_opened',
        text: 'a deschis Mystery Box la $businessName',
        lat: lat,
        lng: lng,
      );
}

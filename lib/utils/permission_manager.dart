import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:nabour_app/utils/logger.dart';

/// Central manager for handling system permission requests sequentially.
/// Prevents multiple simultaneous permission dialogs which can lead to system-level denials.
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._();
  factory PermissionManager() => _instance;
  PermissionManager._();

  Future<void> _queue = Future.value();

  /// Requests location permission sequentially.
  Future<geo.LocationPermission> requestLocationPermission() {
    return _enqueue(() async {
      Logger.info('PermissionManager: Requesting Location permission...', tag: 'PERMISSIONS');
      return await geo.Geolocator.requestPermission();
    });
  }

  /// Requests contacts permission sequentially.
  Future<fc.PermissionStatus> requestContactsPermission() {
    return _enqueue(() async {
      Logger.info('PermissionManager: Requesting Contacts permission...', tag: 'PERMISSIONS');
      return await fc.FlutterContacts.permissions.request(fc.PermissionType.read);
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    
    // Chain onto the current queue
    _queue = _queue.then((_) async {
      try {
        final result = await task();
        completer.complete(result);
      } catch (e, st) {
        Logger.error('PermissionManager error: $e', tag: 'PERMISSIONS', error: e, stackTrace: st);
        completer.completeError(e, st);
      }
    }).catchError((e) {
      // Should not happen as we catch inside then, but for safety
      if (!completer.isCompleted) completer.completeError(e);
    });

    return completer.future;
  }
}

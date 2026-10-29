import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../data/providers/storage_provider.dart';

/// Where an activity is logged, sent with every prayer, dhikr, sadaqah and
/// Quran page so My World can place each one where it happened.
///
/// Reading it never slows a log down: [fields] is synchronous and only reads
/// what is already in memory — the device's live position when a recent one
/// is known, else the location saved on the account. Getting a live position
/// happens beforehand, in the background ([refresh]): the last fix the
/// system already has (instant), then at most every ten minutes a fresh,
/// low-accuracy one. It never asks for permission; without it, logs carry
/// the saved location.
abstract final class LogLocation {
  /// How old a live position may be and still count as where you are.
  static const _freshFor = Duration(hours: 2);

  /// The least time between two background position requests.
  static const _refreshEvery = Duration(minutes: 10);

  static Position? _live;
  static DateTime? _lastRefresh;
  static bool _refreshing = false;

  /// The location fields for a log request, from memory only: the live
  /// position when recent, else the saved one, else nothing. Rounded to
  /// three decimals (about 100 m), the precision the server keeps.
  static Map<String, Object> fields() {
    // Keeps the next one fresh; throttled, and never awaited here.
    unawaited(refresh());

    final live = _live;
    if (live != null && DateTime.now().difference(live.timestamp) < _freshFor) {
      return _encode(live.latitude, live.longitude, 'live');
    }

    final storage = Get.isRegistered<StorageProvider>() ? Get.find<StorageProvider>() : null;
    final lat = storage?.lat, lng = storage?.lng;
    if (lat != null && lng != null && !(lat == 0 && lng == 0)) {
      return _encode(lat, lng, 'saved');
    }
    return const {};
  }

  /// Fetches a live position in the background, at most every ten minutes
  /// (unless [force]d), and only when location is on and already allowed.
  static Future<void> refresh({bool force = false}) async {
    if (_refreshing) return;
    final last = _lastRefresh;
    if (!force && last != null && DateTime.now().difference(last) < _refreshEvery) return;
    _refreshing = true;
    _lastRefresh = DateTime.now();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;

      // The fix the system already has: instant, often recent enough.
      final known = await Geolocator.getLastKnownPosition();
      if (known != null) _accept(known);

      // Then a fresh one; city-level accuracy is plenty, and cheap.
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
      );
      _accept(current);
    } catch (_) {
      // No position this time (timeout, no fix, unsupported): logs use the
      // last one or the saved location.
    } finally {
      _refreshing = false;
    }
  }

  static void _accept(Position position) {
    final current = _live;
    if (current == null || position.timestamp.isAfter(current.timestamp)) _live = position;
  }

  static Map<String, Object> _encode(double lat, double lng, String source) => {
    'lat': double.parse(lat.toStringAsFixed(3)),
    'lng': double.parse(lng.toStringAsFixed(3)),
    'location_source': source,
  };
}

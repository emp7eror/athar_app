import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/providers/api_provider.dart';
import '../utils/error_reporter.dart';

/// Resolves and persists coordinates used by AdhanService. A real build would
/// use the `geolocator` package here; this keeps the integration point clean
/// and syncs coords to the backend so the server can (optionally) validate
/// prayer windows too.
class LocationService extends GetxService {
  final _api = ApiProvider();


  /// Stores a city the user picked by name: its coordinates drive prayer
  /// times exactly as GPS ones would, and its own names are kept as the label
  /// rather than the server's nearest match, so what they chose is what they
  /// see. Works without location permission — the point of it.
  Future<void> saveManualCity({
    required double lat,
    required double lng,
    String? nameAr,
    String? nameEn,
  }) async {
    final storage = Get.find<StorageProvider>();
    storage.saveCoords(lat, lng);
    storage.saveCity(nameAr, nameEn);
    storage.locationIsManual = true;
    storage.locationSetBefore = true;
    try {
      await _api.updateLocation(lat, lng);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      // Offline-first: the city is stored locally regardless of sync success.
    }
  }

  /// Fetches device GPS, persists locally, and syncs to the API.
  /// Throws a translatable key string on failure so the UI can show a snackbar.
  Future<void> refreshFromDevice() async {
    final pos = await _determinePosition();
    await saveCoordinates(pos.latitude, pos.longitude);
  }

  Future<Position> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'location_services_disabled';
    }

    var perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw 'location_permission_denied';
    }

    // 1. Try to get an accurate/current location.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(),
      ).timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      // Continue with fallback.
    }

    // 2. Try again with lower accuracy.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      // Continue with last known location.
    }

    // 3. Use the last known location, even if it is not accurate.
    final lastKnown = await Geolocator.getLastKnownPosition();

    if (lastKnown != null) {
      return lastKnown;
    }

    // 4. Nothing available.
    throw 'location_unavailable';
  }

  Future<void> saveCoordinates(double lat, double lng) async {
      final storage = Get.find<StorageProvider>();
    storage.saveCoords(lat, lng);
    // Read from the device, so it is no longer a hand-picked city.
    storage.locationIsManual = false;
    try {
      final res = await _api.updateLocation(lat, lng);
      final city = res['city'] as Map<String, dynamic>?;
      if (city != null) {
        storage.saveCity(city['name_ar'] as String?, city['name_en'] as String?);
      }
    } catch (e) {

      ErrorReporter.report(e, StackTrace.current);
      // Offline-first: coords are cached locally regardless of sync success.
    }
  }
}

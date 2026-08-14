import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/providers/api_provider.dart';

/// Resolves and persists coordinates used by AdhanService. A real build would
/// use the `geolocator` package here; this keeps the integration point clean
/// and syncs coords to the backend so the server can (optionally) validate
/// prayer windows too.
class LocationService extends GetxService {
  final _api = ApiProvider();


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
    return Geolocator.getCurrentPosition();
  }

  Future<void> saveCoordinates(double lat, double lng) async {
    Get.find<StorageProvider>().saveCoords(lat, lng);
    try {
      await _api.updateLocation(lat, lng);
    } catch (_) {
      // Offline-first: coords are cached locally regardless of sync success.
    }
  }
}

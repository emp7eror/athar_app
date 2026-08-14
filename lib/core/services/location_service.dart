import 'package:get/get.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/providers/api_provider.dart';

/// Resolves and persists coordinates used by AdhanService. A real build would
/// use the `geolocator` package here; this keeps the integration point clean
/// and syncs coords to the backend so the server can (optionally) validate
/// prayer windows too.
class LocationService extends GetxService {
  final _api = ApiProvider();

  Future<void> saveCoordinates(double lat, double lng) async {
    Get.find<StorageProvider>().saveCoords(lat, lng);
    try {
      await _api.updateLocation(lat, lng);
    } catch (_) {
      // Offline-first: coords are cached locally regardless of sync success.
    }
  }
}

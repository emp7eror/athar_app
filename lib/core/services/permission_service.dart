import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Single source of truth for runtime permissions. Owns the request flow and
/// the "permanently denied -> open settings" escape hatch. Call its ensure*
/// methods at the contextual moment, not all at launch.
class PermissionService extends GetxService {
  // ── status (for UI: show what's granted, offer to fix) ──
  Future<bool> get hasNotifications async =>
      await Permission.notification.isGranted;

  Future<bool> get hasLocation async =>
      await Geolocator.checkPermission() == LocationPermission.always ||
          await Geolocator.checkPermission() == LocationPermission.whileInUse;

  // ── request flows (return whether granted) ──
  Future<bool> ensureNotifications() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    return status.isGranted;
  }

  Future<bool> ensureLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false; // caller shows 'location_services_disabled'
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }
}
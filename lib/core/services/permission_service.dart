import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Normalized permission state, unified across geolocator & permission_handler
/// and across Android/iOS so the UI never has to branch on the raw platform API.
enum PermState {
  granted,
  denied, // can ask again
  permanentlyDenied, // must open settings
  restricted, // e.g. iOS parental controls / MDM — cannot be changed by user
  serviceDisabled, // location services turned off at the OS level
}

extension PermStateX on PermState {
  bool get isGranted => this == PermState.granted;

  /// The user can no longer be prompted with the system dialog — the only way
  /// forward is the system settings screen.
  bool get needsSettings =>
      this == PermState.permanentlyDenied || this == PermState.restricted;
}

/// Single source of truth for runtime permissions. Owns *status checks* and
/// *request flows* separately so callers can inspect a decision without
/// re-triggering a system dialog (which is what causes the "prompt every
/// launch" and "loop on permanently-denied" bugs).
///
/// Request methods are contextual — call them from the permission gate at the
/// right moment, never blindly at app start.
class PermissionService extends GetxService {
  // ── LOCATION (via geolocator, which also knows about the OS location switch) ──

  Future<PermState> locationStatus() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return PermState.serviceDisabled;
    }
    return _mapLocation(await Geolocator.checkPermission());
  }

  Future<PermState> requestLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return PermState.serviceDisabled;
    }
    var perm = await Geolocator.checkPermission();
    // Only fire the system dialog when it can still be shown.
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return _mapLocation(perm);
  }

  PermState _mapLocation(LocationPermission perm) {
    switch (perm) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return PermState.granted;
      case LocationPermission.deniedForever:
        return PermState.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return PermState.denied;
    }
  }

  // ── NOTIFICATIONS (via permission_handler; handles Android 13+ POST_NOTIFICATIONS) ──
  // On Android < 13 the status resolves to granted automatically, so no dialog
  // is shown and the gate advances silently.

  Future<PermState> notificationStatus() async =>
      _mapStatus(await ph.Permission.notification.status);

  Future<PermState> requestNotification() async =>
      _mapStatus(await ph.Permission.notification.request());

  PermState _mapStatus(ph.PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) return PermState.granted;
    if (s.isPermanentlyDenied) return PermState.permanentlyDenied;
    if (s.isRestricted) return PermState.restricted;
    return PermState.denied;
  }

  // ── Escape hatches ──
  Future<bool> openSettings() => ph.openAppSettings();
  Future<bool> openLocationServiceSettings() => Geolocator.openLocationSettings();

  // ── Convenience (used outside the gate, e.g. to gate a feature) ──
  Future<bool> get hasLocation async => (await locationStatus()).isGranted;
  Future<bool> get hasNotifications async => (await notificationStatus()).isGranted;
}

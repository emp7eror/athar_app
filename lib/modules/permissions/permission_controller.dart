import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/permission_service.dart';
import '../../data/providers/storage_provider.dart';

/// Which required permission the gate is currently resolving.
enum PermStep { location, notification }

/// Blocking permission gate: resolves Location, then Notifications, then routes
/// into the app. Reactive so the view shows the right explanation + the right
/// action (grant / try again / open settings) for the current OS state.
///
/// Key safety properties:
///  * Never calls the system request API for a permanently-denied/restricted
///    permission (which would no-op forever) — it offers Settings instead.
///  * Re-checks status (not request) when the app resumes from Settings, so
///    granting in Settings advances the flow without another dialog.
///  * If a permission is already granted, that step is skipped silently — the
///    user isn't re-prompted every launch.
class PermissionController extends GetxController with WidgetsBindingObserver {
  final PermissionService _perms = Get.find<PermissionService>();
  final StorageProvider _storage = Get.find<StorageProvider>();

  final Rx<PermStep> step = PermStep.location.obs;
  final Rx<PermState> state = PermState.denied.obs;
  final RxBool busy = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _evaluate();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// When the user returns from the system Settings screen, re-check silently.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      _evaluate();
    }
  }

  bool get isLocationStep => step.value == PermStep.location;

  /// Walks the required permissions in order, advancing past any already
  /// granted, and stops on the first that still needs the user.
  Future<void> _evaluate() async {
    busy.value = true;

    final loc = await _perms.locationStatus();
    if (!loc.isGranted) {
      step.value = PermStep.location;
      state.value = loc;
      busy.value = false;
      return;
    }

    final notif = await _perms.notificationStatus();
    if (!notif.isGranted) {
      step.value = PermStep.notification;
      state.value = notif;
      busy.value = false;
      return;
    }

    busy.value = false;
    _finish();
  }

  /// Primary CTA — request the current permission via the system dialog.
  Future<void> onPrimaryAction() async {
    if (busy.value) return;
    busy.value = true;
    final result = isLocationStep
        ? await _perms.requestLocation()
        : await _perms.requestNotification();
    state.value = result;
    busy.value = false;

    if (result.isGranted) {
      await _evaluate(); // advance to next step / finish
    }
    // If denied/permanentlyDenied/serviceDisabled we stay put; the view now
    // shows "try again" and/or "open settings" based on [state].
  }

  /// "Try again" — for a plain denial we can prompt again; for a permanent
  /// denial there's nothing to retry except re-reading status.
  Future<void> onTryAgain() => _evaluate();

  /// "Open settings" — app settings, or OS location-services settings when the
  /// location switch itself is off. We do NOT hammer the request API here.
  Future<void> onOpenSettings() async {
    if (isLocationStep && state.value == PermState.serviceDisabled) {
      await _perms.openLocationServiceSettings();
    } else {
      await _perms.openSettings();
    }
    // Resume lifecycle callback re-evaluates when the user comes back.
  }

  void _finish() {
    _storage.seenOnboarding = true; // reached the app; onboarding is done
    Get.offAllNamed(_storage.isLoggedIn ? '/home' : '/auth');
  }
}

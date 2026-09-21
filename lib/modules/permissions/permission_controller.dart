import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/permission_service.dart';
import '../../core/services/prayer_notification_scheduler.dart';
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
  /// Whether the notification step can be passed without granting.
  ///
  /// iOS only, for now: App Store Guideline 4.5.4 requires the app to work
  /// with notifications denied, so on iOS the step offers "not now", a denied
  /// system dialog carries on into the app, and the gate never asks again.
  /// Android keeps the blocking step by product choice — to let Android follow
  /// the same path, make this `true` unconditionally.
  static bool get notificationStepSkippable => defaultTargetPlatform == TargetPlatform.iOS;

  final PermissionService _perms = Get.find<PermissionService>();
  final StorageProvider _storage = Get.find<StorageProvider>();

  final Rx<PermStep> step = PermStep.location.obs;
  final Rx<PermState> state = PermState.denied.obs;
  final RxBool busy = false.obs;

  /// The gate routes away exactly once. A system permission dialog closing
  /// sends the app through `resumed`, and that can land *after* the gate has
  /// already left for /auth — re-running the walk would fire a second
  /// `offAllNamed`, tearing down the auth page's controller while its view is
  /// still on screen. The next rebuild would then read a disposed
  /// TextEditingController, which is what made tapping the email field throw
  /// on a first install.
  bool _finished = false;

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
    if (lifecycle == AppLifecycleState.resumed && !_finished) {
      _evaluate();
    }
  }

  bool get isLocationStep => step.value == PermStep.location;

  /// Walks the required permissions in order, advancing past any already
  /// granted, and stops on the first that still needs the user.
  Future<void> _evaluate() async {
    if (_finished) return;
    busy.value = true;

    final loc = await _perms.locationStatus();

    if (!loc.isGranted && !_storage.locationSetBefore) {
      step.value = PermStep.location;
      state.value = loc;
      busy.value = false;
      return;
    }

    final notif = await _perms.notificationStatus();
    // Once turned down on a platform where the step is optional, it is not
    // raised again; Settings → Notifications remains the way back in.
    final asked = notificationStepSkippable && _storage.notifPromptDeclined;
    if (!notif.isGranted && !asked) {
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
      return;
    }

    // Answering "don't allow" is an answer, not a dead end: where the step is
    // optional, carry on into the app instead of leaving the user on a screen
    // whose only buttons ask again.
    if (!isLocationStep && notificationStepSkippable) {
      skipNotifications();
      return;
    }
    // Otherwise we stay put; the view now shows "try again" and/or "open
    // settings" based on [state].
  }

  /// A city chosen by name counts as a location: prayer times come from
  /// coordinates, and these are as real as the device's own. The step is
  /// satisfied, so the gate moves on instead of insisting on permission.
  Future<void> onCityChosen() => _evaluate();

  /// "Not now" — remember it and open the app. Reminders simply don't get
  /// scheduled; everything else works as it always did.
  void skipNotifications() {
    _storage.notifPromptDeclined = true;
    _finish();
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
    if (_finished) return;
    _finished = true;
    // Nothing more to react to; stop listening before the route changes.
    WidgetsBinding.instance.removeObserver(this);

    _storage.seenOnboarding = true; // reached the app; onboarding is done
    // Notification permission was just resolved — (re)build the prayer schedule
    // now instead of waiting for the next foreground resume.
    if (Get.isRegistered<PrayerNotificationScheduler>()) {
      Get.find<PrayerNotificationScheduler>().reschedule();
    }
    Get.offAllNamed(_storage.isLoggedIn ? '/home' : '/auth');
  }
}

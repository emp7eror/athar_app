import 'dart:async';

import 'package:get/get.dart';

import '../../core/services/permission_service.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/providers/storage_provider.dart';
import '../permissions/permission_controller.dart';

/// Decides where to go after the splash: first-run users see onboarding;
/// everyone else goes to the permission gate when location or notifications
/// still need them, and straight into the app when they don't. Auth is
/// resolved only *after* required permissions are handled (see
/// PermissionController).
///
/// It moves on once the logo animation has played through ([logoShown]),
/// and never later than [_longest] in case the animation can't play.
class SplashController extends GetxController {
  final _logoShown = Completer<void>();

  /// At least this long on screen, so the logo isn't a flash on a fast start.
  static const _shortest = Duration(milliseconds: 1500);

  /// Never longer than this, whatever the animation does.
  static const _longest = Duration(seconds: 7);

  /// The logo has finished (or there is none to wait for).
  void logoShown() {
    if (!_logoShown.isCompleted) _logoShown.complete();
  }

  @override
  void onReady() {
    super.onReady();
    _decideNext();
  }

  Future<void> _decideNext() async {
    final storage = Get.find<StorageProvider>();
    // While the logo plays, check whether the permission gate has anything
    // to ask; when it doesn't, the app opens straight past it.
    final needsGate = storage.seenOnboarding ? _needsGate(storage) : Future.value(true);

    await Future.wait([
      Future<void>.delayed(_shortest),
      _logoShown.future.timeout(_longest, onTimeout: () {}),
    ]);
    if (!storage.seenOnboarding) {
      Get.offAllNamed('/onboarding');
    } else if (await needsGate) {
      Get.offAllNamed('/permissions');
    } else {
      PermissionController.enterApp(storage);
    }
  }

  /// Whether location or notifications still need the user. When the check
  /// itself fails, the gate decides (it shows the right step or moves on).
  Future<bool> _needsGate(StorageProvider storage) async {
    try {
      return await PermissionController.pending(Get.find<PermissionService>(), storage) != null;
    } catch (e, st) {
      ErrorReporter.report(e, st);
      return true;
    }
  }
}

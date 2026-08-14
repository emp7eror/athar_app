import 'package:get/get.dart';

import '../../data/providers/storage_provider.dart';

/// Decides where to go after the splash: first-run users see onboarding,
/// everyone else proceeds straight to the permission gate. Auth is resolved
/// only *after* required permissions are handled (see PermissionController).
class SplashController extends GetxController {
  final StorageProvider _storage = Get.find<StorageProvider>();

  @override
  void onReady() {
    super.onReady();
    _decideNext();
  }

  Future<void> _decideNext() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    final storage = Get.find<StorageProvider>();
    if (!storage.seenOnboarding) {
      Get.offAllNamed('/onboarding');
    } else {
      Get.offAllNamed('/permissions');
    }
  }
}

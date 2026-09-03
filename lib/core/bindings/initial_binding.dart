import 'package:get/get.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/providers/api_provider.dart';
import '../network/dio_client.dart';
import '../localization/localization_controller.dart';
import '../theme/theme_controller.dart';
import '../services/adhan_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/prayer_notification_scheduler.dart';
import '../services/sound_service.dart';
import '../services/timezone_service.dart';

/// Registered once at app start (from `main()`, before `runApp`).
///
/// Split into a synchronous part (plain singletons) and [initAsync] for the
/// services that must finish their `init()` — notifications/timezone and the
/// audio player — before anything (scheduler, settings screen) uses them.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core singletons (permanent for app lifetime).
    Get.put(StorageProvider(), permanent: true);
    Get.put(LocalizationController(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.put(DioClient(), permanent: true);
    Get.put(ApiProvider(), permanent: true);
    Get.put(AdhanService(), permanent: true);
    Get.put(PermissionService(), permanent: true);
    Get.put(LocationService(), permanent: true);
  }

  /// Awaited in `main()` so downstream code can safely `Get.find` these.
  static Future<void> initAsync() async {
    await Get.putAsync(() => NotificationService().init(), permanent: true);
    await Get.putAsync(() => SoundService().init(), permanent: true);
    await Get.putAsync(() => TimezoneService().init(), permanent: true);
    // Scheduler depends on NotificationService + AdhanService being ready.
    Get.put(PrayerNotificationScheduler(), permanent: true);
  }
}

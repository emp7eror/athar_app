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

/// Registered once at app start (main.dart initialBinding).
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
    Get.putAsync(() => NotificationService().init(), permanent: true);
  }
}

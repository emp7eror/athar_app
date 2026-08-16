import 'package:get/get.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/utils/snackbar.dart';
import '../../data/providers/storage_provider.dart';

class NotificationSettingsController extends GetxController {
  final _store = Get.find<StorageProvider>();
  final _notif = Get.find<NotificationService>();
  final _scheduler = Get.find<PrayerNotificationScheduler>();
  final _perm = Get.find<PermissionService>();

  // Reactive mirrors of persisted preferences.
  final prayerEnabled = false.obs;
  final postEnabled = false.obs;
  final upcomingEnabled = false.obs;
  final prayerSoundId = ''.obs;
  final reminderSoundId = ''.obs;

  /// OS-level delivery status, so the screen can show a "notifications are off"
  /// banner and stop pretending everything is scheduled.
  final status = NotifStatus.ready.obs;

  @override
  void onInit() {
    super.onInit();
    prayerEnabled.value = _store.notifPrayerEnabled;
    postEnabled.value = _store.notifPostPrayerEnabled;
    upcomingEnabled.value = _store.notifUpcomingEnabled;
    prayerSoundId.value = _store.prayerSoundId;
    reminderSoundId.value = _store.reminderSoundId;
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    status.value = await _notif.checkStatus();
  }

  Future<void> _apply() async {
    status.value = await _scheduler.reschedule();
  }

  Future<void> setPrayerEnabled(bool v) async {
    prayerEnabled.value = v;
    _store.notifPrayerEnabled = v;
    await _apply();
  }

  Future<void> setPostEnabled(bool v) async {
    postEnabled.value = v;
    _store.notifPostPrayerEnabled = v;
    await _apply();
  }

  Future<void> setUpcomingEnabled(bool v) async {
    upcomingEnabled.value = v;
    _store.notifUpcomingEnabled = v;
    await _apply();
  }

  Future<void> setPrayerSound(String id) async {
    prayerSoundId.value = id;
    _store.prayerSoundId = id;
    await _apply();
  }

  Future<void> setReminderSound(String id) async {
    reminderSoundId.value = id;
    _store.reminderSoundId = id;
    await _apply();
  }

  Future<void> sendTest() async {
    await refreshStatus();
    if (status.value != NotifStatus.ready) {
      // Try a runtime request once; if still not ready, point to settings.
      await _notif.requestPermission();
      await refreshStatus();
      if (status.value != NotifStatus.ready) {
        AppSnackbar.error('notif_disabled_title'.tr, 'notif_disabled_msg'.tr);
        return;
      }
    }
    await _notif.showTest('app_name'.tr, 'test_notif_body'.tr);
    AppSnackbar.show('app_name'.tr, 'test_sent'.tr);
  }

  Future<void> openSystemSettings() async {
    await _perm.openSettings();
  }
}

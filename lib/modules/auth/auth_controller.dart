import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/models/user_model.dart';

class AuthController extends GetxController {
  final _api = Get.find<ApiProvider>();
  final _storage = Get.find<StorageProvider>();

  final isRegister = false.obs;
  final loading = false.obs;

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final age = TextEditingController();

  void toggleMode() => isRegister.toggle();

  Future<void> submit() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final Map<String, dynamic> res = isRegister.value
          ? await _api.register({
              'name': name.text.trim(),
              'email': email.text.trim(),
              'password': password.text,
              'age': int.tryParse(age.text) ?? 0,
            })
          : await _api.login(email.text.trim(), password.text);

      _storage.token = res['token'];
      _storage.cachedUser = res['user'];
      await _registerFcmToken();
      // Best-effort: grab location so prayer times are correct on first load.
      try {
        await Get.find<LocationService>().refreshFromDevice();
      } catch (e) {
        ErrorReporter.report(e, StackTrace.current);
        // Non-fatal — user can set it from Home; Adhan falls back to Makkah.
      }

      // IMPORTANT: reset loading BEFORE navigation. `Get.offAllNamed` triggers
      // this controller's onClose(), which disposes the TextEditingControllers.
      // Any subsequent Obx rebuild (from setting loading here after nav) would
      // then read disposed controllers and throw.
      loading.value = false;
      Get.offAllNamed('/home');
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      AppSnackbar.error('app_name'.tr, e.message,
          position: SnackPosition.BOTTOM);
      loading.value = false;
    }
  }

  UserModel? get cachedUser {
    final u = _storage.cachedUser;
    return u == null ? null : UserModel.fromJson(u);
  }

  @override
  void onClose() {
    name.dispose(); email.dispose(); password.dispose(); age.dispose();
    super.onClose();
  }

  Future<void> _registerFcmToken() async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null) await _api.updateFcmToken(t);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      // Non-fatal: never block login if FCM/registration hiccups.
    }
  }

  // ── Anonymous / guest login ────────────────────────────────────────
  /// Continues into the app without a real account. Only the device id is
  /// sent to the backend, which returns the (existing or newly-provisioned)
  /// anonymous user tied to this device. Hydrates the local session exactly
  /// like a normal login so downstream code is unaware of the difference.
  Future<void> continueAsGuest() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final deviceId = await _deviceId();
      if (deviceId.isEmpty) {
        AppSnackbar.error('app_name'.tr, 'guest_device_id_error'.tr,
            position: SnackPosition.BOTTOM);
        loading.value = false;
        return;
      }

      final res = await _api.anonymousLogin(deviceId);
      final token = res['token'];
      final user = res['user'];
      if (token is! String || token.isEmpty || user is! Map) {
        AppSnackbar.error('app_name'.tr, 'guest_login_failed'.tr,
            position: SnackPosition.BOTTOM);
        loading.value = false;
        return;
      }
      _storage.token = token;
      _storage.cachedUser = Map<String, dynamic>.from(user);

      await _registerFcmToken();
      try {
        await Get.find<LocationService>().refreshFromDevice();
      } catch (e) {
        ErrorReporter.report(e, StackTrace.current);
        /* non-fatal */
      }

      // Reset loading BEFORE navigation — `Get.offAllNamed` triggers this
      // controller's onClose(), which disposes the TextEditingControllers.
      // Any Obx rebuild caused by setting loading afterwards would read the
      // disposed controllers and crash.
      loading.value = false;
      Get.offAllNamed('/home');
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      AppSnackbar.error('app_name'.tr, e.message,
          position: SnackPosition.BOTTOM);
      loading.value = false;
    }
  }

  /// Best-available stable per-install device identifier. Android's
  /// `androidId` (SSAID) survives app reinstall; iOS's `identifierForVendor`
  /// survives reinstall as long as any app from the same vendor stays
  /// installed. Both are fine as backend correlation keys for a guest.
  Future<String> _deviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return a.id;
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.identifierForVendor ?? '';
    }
    return '';
  }
}

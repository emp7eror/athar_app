import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      
      Get.offAllNamed('/home');
    } on ApiException catch (e) {
      Get.snackbar('app_name'.tr, e.message, snackPosition: SnackPosition.BOTTOM);
    } finally {
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
    } catch (_) {
      // Non-fatal: never block login if FCM/registration hiccups.
    }
  }}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';

class ProfileController extends GetxController {
  final _api     = Get.find<ApiProvider>();
  final _storage = Get.find<StorageProvider>();

  final user       = Rxn<UserModel>();
  final loading    = false.obs;
  final uploading  = false.obs;
  final editing    = false.obs;

  // edit form
  late final nameCtrl = TextEditingController();
  final selectedAge   = 18.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _refreshUser();
  }

  void _loadUser() {
    final cached = _storage.cachedUser;
    if (cached != null) user.value = UserModel.fromJson(cached);
  }

  /// Pulls the latest profile from the server so monthly-reset fields
  /// (score / last_score / best_score) don't show stale cached values.
  Future<void> _refreshUser() async {
    try {
      final res = await _api.getProfile();
      final data = res['user'] as Map<String, dynamic>;
      _storage.cachedUser = data;
      user.value = UserModel.fromJson(data);
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    }
  }

  void startEdit() {
    nameCtrl.text       = user.value?.name ?? '';
    selectedAge.value   = user.value?.age ?? 18;
    editing.value       = true;
  }

  void cancelEdit() => editing.value = false;

  Future<void> saveProfile() async {
    if (nameCtrl.text.trim().isEmpty) return;
    loading.value = true;
    try {
      final res = await _api.updateProfile(
        name: nameCtrl.text.trim(),
        age:  selectedAge.value,
      );
      _storage.cachedUser = res['user'] as Map<String, dynamic>;
      user.value = UserModel.fromJson(res['user']);
      editing.value = false;
      AppSnackbar.show('profile'.tr, 'profile_updated'.tr);
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      AppSnackbar.error('profile'.tr, e.message);
    } finally {
      loading.value = false;
    }
  }

  Future<void> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;

    uploading.value = true;
    try {
      final res = await _api.updateAvatar(picked.path);
      final updated = Map<String, dynamic>.from(_storage.cachedUser ?? {});
      updated['avatar_path'] = res['avatar_path'];
      updated['avatar_url']  = res['avatar_url'];
      _storage.cachedUser = updated;
      user.value = UserModel.fromJson(updated);
      AppSnackbar.show('profile'.tr, 'avatar_updated'.tr);
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);

      AppSnackbar.error('profile'.tr, e.message);
    } finally {
      uploading.value = false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _storage.clear();
    Get.offAllNamed('/auth');
  }

  @override
  void onClose() { nameCtrl.dispose(); super.onClose(); }
}
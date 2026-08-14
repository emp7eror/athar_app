import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/snackbar.dart';
import '../../data/providers/api_provider.dart';
import '../../data/models/friend_model.dart';

class FriendsController extends GetxController {
  final _api = Get.find<ApiProvider>();

  final friends = <FriendModel>[].obs;
  final pending = <PendingRequest>[].obs;
  final loading = false.obs;
  final codeInput = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final res = await _api.friends();
      friends.value = (res['friends'] as List).map((e) => FriendModel.fromJson(e)).toList();
      pending.value =
          (res['pending_incoming'] as List).map((e) => PendingRequest.fromJson(e)).toList();
    } on ApiException catch (e) {
      AppSnackbar.error('friends'.tr, e.message);
    } finally {
      loading.value = false;
    }
  }

  Future<void> add() async {
    final code = codeInput.text.trim().toUpperCase();
    if (code.length != 6) return;
    try {
      await _api.addFriend(code);
      codeInput.clear();
      AppSnackbar.show('friends'.tr, 'add_friend'.tr, position: SnackPosition.BOTTOM);
      await load();
    } on ApiException catch (e) {
      AppSnackbar.error('friends'.tr, e.message, position: SnackPosition.BOTTOM);
    }
  }

  Future<void> respond(int friendshipId, String action) async {
    try {
      await _api.respond(friendshipId, action);
      await load();
    } on ApiException catch (e) {
      AppSnackbar.error('friends'.tr, e.message);
    }
  }

  Future<void> nudge(FriendModel f) async {
    try {
      await _api.nudge(f.id);
      AppSnackbar.show('nudge'.tr, f.name, position: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      AppSnackbar.error('nudge'.tr, e.message, position: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    codeInput.dispose();
    super.onClose();
  }
}

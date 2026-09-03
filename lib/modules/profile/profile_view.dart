import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/framed_avatar.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Obx(() => RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Text('profile'.tr,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 24),
              _avatarCard(context),
              const SizedBox(height: 24),
              if (controller.editing.value) _editForm(context) else _infoCard(context),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: Icon(Icons.logout, color: colors.error),
                label: Text('logout'.tr,
                    style: TextStyle(color: colors.error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _avatarCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Stack(children: [
        Obx(() => controller.uploading.value
            ? Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : _avatarWidget(context, radius: 40)),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: controller.pickAndUploadAvatar,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              child: Icon(Icons.camera_alt, color: colors.onPrimary, size: 18),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _avatarWidget(BuildContext context, {double radius = 24}) {
    final u         = controller.user.value;
    final avatarUrl = (Get.find<StorageProvider>().cachedUser ?? {})['avatar_url'] as String?;
    return FramedAvatar(
      name: u?.name ?? '',
      avatarUrl: avatarUrl,
      frameAsset: u?.level?.frame,
      level: u?.level?.level,
      radius: radius,
    );
  }

  Widget _infoCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final u      = controller.user.value;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        _infoRow(context, Icons.person_outline, 'name'.tr,    u?.name ?? '-'),
        const Divider(height: 24),
        _infoRow(context, Icons.email_outlined,  'email'.tr,  u?.email ?? '-'),
        const Divider(height: 24),
        _infoRow(context, Icons.cake_outlined,   'age'.tr,    '${u?.age ?? '-'}'),
        const Divider(height: 24),
        // _infoRow(context, Icons.tag,             'my_code'.tr, u?.userCode ?? '-'),
        // const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.startEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text('edit_profile'.tr),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, color: colors.primary, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ]),
    ]);
  }

  Widget _editForm(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('edit_profile'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        TextField(
          controller: controller.nameCtrl,
          decoration: InputDecoration(labelText: 'name'.tr),
        ),
        const SizedBox(height: 16),
        Text('age'.tr,
            style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(12)),
          child: Obx(() => ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 2.0,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
                initialItem: controller.selectedAge.value - 10),
            onSelectedItemChanged: (i) => controller.selectedAge.value = i + 10,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 91,
              builder: (ctx, i) {
                final age      = i + 10;
                final selected = age == controller.selectedAge.value;
                final c        = Theme.of(ctx).colorScheme;
                return Center(
                  child: Text('$age',
                      style: TextStyle(
                        fontSize:   selected ? 22 : 16,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.normal,
                        color:      selected ? c.primary : c.onSurfaceVariant,
                      )),
                );
              },
            ),
          )),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.cancelEdit,
              child: Text('cancel'.tr),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton(
              onPressed: controller.loading.value ? null : controller.saveProfile,
              child: controller.loading.value
                  ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: colors.onPrimary, strokeWidth: 2))
                  : Text('save'.tr),
            )),
          ),
        ]),
      ]),
    );
  }

  void _confirmLogout(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('logout'.tr,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text('logout_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); controller.logout(); },
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.error, foregroundColor: colors.onError),
            child: Text('logout'.tr),
          ),
        ],
      ),
    );
  }
}
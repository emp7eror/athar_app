import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/storage_provider.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Obx(() => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── رأس الصفحة ──
            Row(
              children: [
                Text('profile'.tr,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),

            // ── بطاقة الصورة والمعلومات ──
            _avatarCard(),
            const SizedBox(height: 16),

            // ── المستوى والإحصائيات ──
            _statsRow(),
            const SizedBox(height: 24),

            // ── تعديل الملف ──
            if (controller.editing.value) _editForm()
            else _infoCard(),

            const SizedBox(height: 32),

            // ── تسجيل الخروج ──
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: Text('logout'.tr,
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        )),
      ),
    );
  }

  // ── الصورة الشخصية ──────────────────────────────────────────
  Widget _avatarCard() {
    final u = controller.user.value;
    return Center(
      child: Stack(
        children: [
          Obx(() => controller.uploading.value
              ? Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : _avatarWidget(u, radius: 50)),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: controller.pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarWidget(user, {double radius = 24}) {
    final user = Get.find<StorageProvider>().cachedUser;

    final u = controller.user.value;
    final avatarUrl = (user ?? {})['avatar_url'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.primary,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        (u?.name.isNotEmpty == true) ? u!.name[0].toUpperCase() : '?',
        style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── إحصائيات سريعة ─────────────────────────────────────────
  Widget _statsRow() {
    final u = controller.user.value;
    final isAr = Get.locale?.languageCode == 'ar';
    final levelTitle = isAr ? u?.level?.titleAr : u?.level?.titleEn;
    return Row(
      children: [
        _statChip(Icons.star, '${u?.totalPoints ?? 0}', 'points'.tr),
        const SizedBox(width: 10),
        _statChip(Icons.local_fire_department, '${u?.currentStreak ?? 0}', 'streak'.tr),
        const SizedBox(width: 10),
        _statChip(Icons.emoji_events, levelTitle ?? '-', 'level'.tr),
      ],
    );
  }

  Widget _statChip(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
    ),
  );

  // ── عرض المعلومات ───────────────────────────────────────────
  Widget _infoCard() {
    final u = controller.user.value;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        _infoRow(Icons.person_outline, 'name'.tr, u?.name ?? '-'),
        const Divider(height: 24),
        _infoRow(Icons.email_outlined, 'email'.tr, u?.email ?? '-'),
        const Divider(height: 24),
        _infoRow(Icons.cake_outlined, 'age'.tr, '${u?.age ?? '-'}'),
        const Divider(height: 24),
        _infoRow(Icons.tag, 'my_code'.tr, u?.userCode ?? '-'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.startEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            label: Text('edit_profile'.tr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ]),
    ],
  );

  // ── نموذج التعديل ───────────────────────────────────────────
  Widget _editForm() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('edit_profile'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),

      // الاسم
      TextField(
        controller: controller.nameCtrl,
        decoration: InputDecoration(
          labelText: 'name'.tr,
          filled: true, fillColor: AppColors.bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 16),

      // العمر — Spinner
      Text('age'.tr,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Container(
        height: 120,
        decoration: BoxDecoration(
            color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
        child: Obx(() => ListWheelScrollView.useDelegate(
          itemExtent: 40,
          diameterRatio: 2.0,
          physics: const FixedExtentScrollPhysics(),
          controller: FixedExtentScrollController(
              initialItem: controller.selectedAge.value - 10),
          onSelectedItemChanged: (i) => controller.selectedAge.value = i + 10,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: 91, // 10 - 100
            builder: (context, i) {
              final age = i + 10;
              final selected = age == controller.selectedAge.value;
              return Center(
                child: Text(
                  '$age',
                  style: TextStyle(
                    fontSize: selected ? 22 : 16,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.normal,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              );
            },
          ),
        )),
      ),
      const SizedBox(height: 20),

      // أزرار
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: controller.cancelEdit,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.textMuted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('cancel'.tr,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Obx(() => ElevatedButton(
            onPressed: controller.loading.value ? null : controller.saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: controller.loading.value
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('save'.tr,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          )),
        ),
      ]),
    ]),
  );

  // ── تأكيد تسجيل الخروج ─────────────────────────────────────
  void _confirmLogout(BuildContext context) {
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
                backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: Text('logout'.tr),
          ),
        ],
      ),
    );
  }
}
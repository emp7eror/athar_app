import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';

import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/gender_selector.dart';
import '../tour/app_tours.dart';
import 'delete_account_dialog.dart';
import 'profile_binding.dart';
import 'profile_controller.dart';

/// Profile: who you are in Athar — your framed photo, level and totals — then
/// your details, editing them, and signing out. Opened from Settings and from
/// the avatar on Home.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  /// Opens the profile with its own controller, made for the page and
  /// removed when it closes — so every visit starts fresh.
  static Future<void> open() async {
    await Get.to(() => const ProfileView(), binding: ProfileBinding());
  }

  @override
  Widget build(BuildContext context) {
    return TourAutoStart(
      pageId: TourPages.profile,
      child: Scaffold(
      appBar: AtharAppBar(
        title: 'profile'.tr,
        actions: const [
          TourHelpButton(pageId: TourPages.profile, style: TourHelpStyle.appBar),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => RefreshIndicator(
            onRefresh: controller.refreshAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, AtharSpace.xxl),
              // Keeps the whole page built so tour steps can scroll to any item.
              scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
              children: [
                if (controller.editing.value)
                  _EditForm(controller: controller)
                else
                  TourTarget(id: TourTargets.profileInfo, child: _Details(controller: controller)),
                const SizedBox(height: AtharSpace.lg),
                TourTarget(
                  id: TourTargets.profileLogout,
                  child: AtharListGroup(
                    children: [
                      AtharListRow(
                        icon: Icons.logout_rounded,
                        title: 'logout'.tr,
                        destructive: true,
                        showChevron: false,
                        onTap: _confirmLogout,
                      ),
                      // Deleting the account lives with the other account
                      // actions, one step deeper behind its own confirmation.
                      AtharListRow(
                        icon: Icons.delete_forever_rounded,
                        title: 'delete_account'.tr,
                        subtitle: 'delete_account_row_sub'.tr,
                        destructive: true,
                        showChevron: false,
                        onTap: DeleteAccountDialog.show,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showAtharConfirm(
      title: 'logout'.tr,
      message: 'logout_confirm'.tr,
      confirmLabel: 'logout'.tr,
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (confirmed) controller.logout();
  }
}

/// The first row of the details: the photo — plain, without the level frame
/// — and changing it.
class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.controller});

  final ProfileController controller;

  static const _size = 60.0;

  @override
  Widget build(BuildContext context) {
    final u = controller.user.value;
    final avatarUrl = (Get.find<StorageProvider>().cachedUser ?? {})['avatar_url'] as String?;
    final scheme = context.colors;
    final name = u?.name ?? '';

    // The photo cut to a circle, filling it whatever its own shape, inside a
    // ring of the same circle; the initial when there is no photo.
    final initial = Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: context.type.sectionTitle.copyWith(color: scheme.onPrimary),
      ),
    );
    final photo = Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: scheme.primary,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? initial
              : Image.network(
                  avatarUrl,
                  width: _size,
                  height: _size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => initial,
                ),
        ),
      ),
    );

    return InkWell(
      onTap: controller.pickAndUploadAvatar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.sm),
        child: Row(
          children: [
            // Targets the avatar itself so the tour spotlight hugs the photo
            // and its camera button.
            TourTarget(
              id: TourTargets.profileAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Obx(
                    () => controller.uploading.value
                        ? const SizedBox.square(
                            dimension: _size,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : photo,
                  ),
                  PositionedDirectional(
                    bottom: -2,
                    end: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.athar.card, width: 2),
                      ),
                      child: Icon(Icons.photo_camera_rounded, size: 14, color: context.colors.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AtharSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('profile_photo'.tr, style: context.type.cardTitle),
                  const SizedBox(height: 2),
                  Text('profile_change_photo'.tr, style: context.type.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final u = controller.user.value;
    final gender = u?.gender;

    return AtharListGroup(
      title: 'profile_details'.tr,
      children: [
        _PhotoRow(controller: controller),
        AtharListRow(icon: Icons.person_rounded, title: 'name'.tr, value: u?.name ?? '-', showChevron: false),
        AtharListRow(icon: Icons.email_rounded, title: 'email'.tr, value: u?.email ?? '-', showChevron: false),
        AtharListRow(
          icon: Icons.cake_rounded,
          title: 'age'.tr,
          value: (u?.age ?? 0) == 0 ? 'age_not_set'.tr : '${u!.age}',
          showChevron: false,
        ),
        if (gender == 'male' || gender == 'female')
          AtharListRow(
            icon: gender == 'female' ? Icons.female_rounded : Icons.male_rounded,
            title: 'gender'.tr,
            value: 'gender_$gender'.tr,
            showChevron: false,
          ),
        AtharListRow(icon: Icons.edit_rounded, title: 'edit_profile'.tr, onTap: controller.startEdit),
      ],
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return AtharCard(
      padding: const EdgeInsets.all(AtharSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('edit_profile'.tr, style: context.type.sectionTitle)),
          const SizedBox(height: AtharSpace.md),
          TextField(
            controller: controller.nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: 'name'.tr, prefixIcon: const Icon(Icons.person_rounded)),
          ),
          const SizedBox(height: AtharSpace.md),
          TextField(
            controller: controller.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(labelText: 'email'.tr, prefixIcon: const Icon(Icons.email_rounded)),
          ),
          const SizedBox(height: AtharSpace.lg),
          Text('gender'.tr, style: context.type.cardTitle),
          const SizedBox(height: AtharSpace.xs),
          Obx(
            () => GenderSelector(
              value: controller.selectedGender.value,
              onChanged: (v) => controller.selectedGender.value = v,
            ),
          ),
          const SizedBox(height: AtharSpace.lg),
          Text('age'.tr, style: context.type.cardTitle),
          const SizedBox(height: AtharSpace.xs),
          Container(
            height: 132,
            decoration: BoxDecoration(
              color: context.athar.beige,
              borderRadius: BorderRadius.circular(AtharRadius.md),
            ),
            child: Obx(
              () => ListWheelScrollView.useDelegate(
                itemExtent: 44,
                diameterRatio: 2.0,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(
                  initialItem: ProfileController.ageWheelIndex(controller.selectedAge.value),
                ),
                onSelectedItemChanged: (i) => controller.selectedAge.value = ProfileController.ageAtWheel(i),
                childDelegate: ListWheelChildBuilderDelegate(
                  // One extra row at the top for "not set" (age 0).
                  childCount: 92,
                  builder: (ctx, i) {
                    final age = ProfileController.ageAtWheel(i);
                    final selected = age == controller.selectedAge.value;
                    return Center(
                      child: Text(
                        age == 0 ? 'age_not_set'.tr : '$age',
                        style: selected
                            ? ctx.text.titleLarge?.copyWith(color: scheme.primary)
                            : ctx.text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: AtharSpace.lg),
          Row(
            children: [
              Expanded(
                child: AtharButton(
                  label: 'cancel'.tr,
                  variant: AtharButtonVariant.secondary,
                  onPressed: controller.cancelEdit,
                ),
              ),
              const SizedBox(width: AtharSpace.sm),
              Expanded(
                flex: 2,
                child: Obx(
                  () => AtharButton(
                    label: 'save'.tr,
                    loading: controller.loading.value,
                    onPressed: controller.saveProfile,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

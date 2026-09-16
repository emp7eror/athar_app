import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';

import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../../data/providers/storage_provider.dart';
import '../../widgets/framed_avatar.dart';
import '../../widgets/gender_selector.dart';
import '../../widgets/level_progress_card.dart';
import '../tour/app_tours.dart';
import 'profile_controller.dart';

/// Profile: who you are in Athar — your framed photo, level and totals — then
/// your details, editing them, and signing out.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  /// Room under the content for the floating nav bar.
  static const _navClearance = 160.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => RefreshIndicator(
            onRefresh: controller.refreshAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, _navClearance),
              // Keeps the whole page built so tour steps can scroll to any item.
              scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
              children: [
                AtharPageHeader(
                  title: 'profile'.tr,
                  trailing: const [TourHelpButton(pageId: TourPages.profile)],
                ),
                const SizedBox(height: AtharSpace.md),
                _IdentityCard(controller: controller),
                const SizedBox(height: AtharSpace.md),
                LevelProgressCard(level: controller.user.value?.level),
                const SizedBox(height: AtharSpace.xl),
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
                    ],
                  ),
                ),
              ],
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

/// The photo in its level frame, name, level title and totals, on the brand
/// surface.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final onBrand =  context.colors.onSurface;
    final u = controller.user.value;
    final isAr = Get.locale?.languageCode == 'ar';
    final avatarUrl = (Get.find<StorageProvider>().cachedUser ?? {})['avatar_url'] as String?;

    return AtharCard(
      // tone: AtharCardTone.surface,
      padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.xl, AtharSpace.lg, AtharSpace.lg),
      child: Column(
        children: [
          // Targets the avatar itself so the tour spotlight hugs the photo and
          // its camera button.
          TourTarget(
            id: TourTargets.profileAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Obx(
                  () => controller.uploading.value
                      ?  SizedBox.square(
                          dimension: 122,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: onBrand)),
                        )
                      : FramedAvatar(
                          name: u?.name ?? '',
                          avatarUrl: avatarUrl,
                          frameAsset: u?.level?.frame,
                          level: u?.level?.level,
                          radius: 34,
                        ),
                ),
                PositionedDirectional(
                  bottom: -4,
                  end: -4,
                  child: AtharIconButton(
                    icon: Icons.photo_camera_rounded,
                    tooltip: 'profile_change_photo'.tr,
                    variant: AtharIconButtonVariant.filled,
                    onPressed: controller.pickAndUploadAvatar,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AtharSpace.md),
          Text(
            u?.name ?? '',
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(color: onBrand),
          ),
          if (u?.level != null) ...[
            const SizedBox(height: AtharSpace.xxs),
            Text(
              u!.level!.displayName(isAr),
              textAlign: TextAlign.center,
              style: context.text.titleSmall?.copyWith(color: context.colors.onSurface),
            ),
          ],
          const SizedBox(height: AtharSpace.lg),
          Row(
            children: [
              Expanded(child: _HeroStat(icon: Icons.star_rounded, value: '${u?.totalPoints ?? 0}', label: 'points'.tr)),
              Expanded(
                child: _HeroStat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${u?.currentStreak ?? 0}',
                  label: 'streak'.tr,
                ),
              ),
              Expanded(child: _HeroStat(icon: Icons.military_tech_rounded, value: '${u?.bestScore ?? 0}', label: 'best_score'.tr)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onBrand = context.colors.onSurface;

    return MergeSemantics(
      child: Column(
        children: [
          Icon(icon, size: AtharSize.icon, color: context.athar.gold),
          const SizedBox(height: AtharSpace.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, style: context.type.statValue.copyWith(color: onBrand)),
          ),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(color: onBrand.withValues(alpha: 0.8)),
          ),
        ],
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
        AtharListRow(icon: Icons.person_rounded, title: 'name'.tr, value: u?.name ?? '-', showChevron: false),
        AtharListRow(icon: Icons.email_rounded, title: 'email'.tr, value: u?.email ?? '-', showChevron: false),
        AtharListRow(icon: Icons.cake_rounded, title: 'age'.tr, value: '${u?.age ?? '-'}', showChevron: false),
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
                controller: FixedExtentScrollController(initialItem: controller.selectedAge.value - 10),
                onSelectedItemChanged: (i) => controller.selectedAge.value = i + 10,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 91,
                  builder: (ctx, i) {
                    final age = i + 10;
                    final selected = age == controller.selectedAge.value;
                    return Center(
                      child: Text(
                        '$age',
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

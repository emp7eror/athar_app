import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/services/permission_service.dart';
import '../../widgets/city_picker_sheet.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/ui/athar_ui.dart';
import 'permission_controller.dart';

/// Why Athar asks for location and notifications, and the way to grant them.
///
/// Always rendered on the brand's dark ground, whatever theme the app is in,
/// so the first screen after onboarding is unmistakably Athar. Everything
/// inside is themed dark to match.
class PermissionGateView extends GetView<PermissionController> {
  const PermissionGateView({super.key});

  @override
  Widget build(BuildContext context) {
    final preset = Get.find<ThemeController>().preset;
    final dark = AppTheme.build(preset, Brightness.dark, arabic: Get.find<LocalizationController>().isRtl);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: dark,
        child: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Obx(() {
                final step = controller.step.value;
                final state = controller.state.value;
                final isLocation = step == PermStep.location;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AtharSpace.sm),
                      const _BrandLogo(),
                      _StepDots(activeIndex: isLocation ? 0 : 1),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: AtharSpace.xl),
                              _IconBadge(
                                icon: isLocation
                                    ? Icons.location_on_rounded
                                    : Icons.notifications_active_rounded,
                              ),
                              const SizedBox(height: AtharSpace.xl),
                              Semantics(
                                header: true,
                                child: Text(
                                  (isLocation ? 'perm_location_title' : 'perm_notif_title').tr,
                                  textAlign: TextAlign.center,
                                  style: context.text.headlineMedium,
                                ),
                              ),
                              const SizedBox(height: AtharSpace.md),
                              Text(
                                (isLocation ? 'perm_location_msg' : 'perm_notif_msg').tr,
                                textAlign: TextAlign.center,
                                style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                              _StateNote(state: state),
                              const SizedBox(height: AtharSpace.xl),
                            ],
                          ),
                        ),
                      ),
                      _Actions(isLocation: isLocation, state: state, busy: controller.busy.value),
                      const SizedBox(height: AtharSpace.lg),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Text(
          'أثر',
          style: context.text.headlineLarge?.copyWith(color: context.athar.gold),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AtharSpace.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 2; i++)
            AnimatedContainer(
              duration: AtharMotion.base,
              margin: const EdgeInsets.symmetric(horizontal: AtharSpace.xxs),
              width: i == activeIndex ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == activeIndex ? context.athar.gold : context.colors.outline,
                borderRadius: BorderRadius.circular(AtharRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.athar.card, shape: BoxShape.circle),
      child: Container(
        width: 92,
        height: 92,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 44, color: context.athar.gold),
      ),
    );
  }
}

/// Contextual explanation shown only when a permission still blocks progress.
class _StateNote extends StatelessWidget {
  const _StateNote({required this.state});

  final PermState state;

  @override
  Widget build(BuildContext context) {
    final String? key = switch (state) {
      PermState.denied => 'perm_denied_note',
      PermState.permanentlyDenied => 'perm_permanent_note',
      PermState.restricted => 'perm_restricted_note',
      PermState.serviceDisabled => 'perm_service_off_note',
      PermState.granted => null,
    };
    if (key == null) return const SizedBox.shrink();

    final gold = context.athar.gold;

    return Padding(
      padding: const EdgeInsets.only(top: AtharSpace.xl),
      child: Container(
        padding: const EdgeInsets.all(AtharSpace.md),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AtharRadius.card),
          border: Border.all(color: gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_rounded, size: AtharSize.icon, color: gold),
            const SizedBox(width: AtharSpace.sm),
            Expanded(child: Text(key.tr, style: context.text.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

/// The action buttons, driven by the current permission [state].
class _Actions extends StatelessWidget {
  const _Actions({required this.isLocation, required this.state, required this.busy});

  final bool isLocation;
  final PermState state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PermissionController>();
    final needsSettings = state.needsSettings || state == PermState.serviceDisabled;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AtharButton(
          label: needsSettings ? 'perm_open_settings'.tr : (isLocation ? 'perm_location_cta' : 'perm_notif_cta').tr,
          expand: true,
          loading: busy,
          onPressed: needsSettings ? controller.onOpenSettings : controller.onPrimaryAction,
        ),
        if (needsSettings) ...[
          const SizedBox(height: AtharSpace.sm),
          AtharButton(
            label: 'perm_try_again'.tr,
            variant: AtharButtonVariant.secondary,
            expand: true,
            onPressed: busy ? null : controller.onTryAgain,
          ),
        ],
        // Location has an answer that needs no permission at all: name the
        // city. Offered in every state, so denying the system dialog is never
        // a dead end.
        if (isLocation) ...[
          const SizedBox(height: AtharSpace.xs),
          AtharButton(
            label: 'perm_location_pick_city'.tr,
            icon: Icons.location_city_rounded,
            variant: AtharButtonVariant.ghost,
            expand: true,
            onPressed: busy
                ? null
                : () async {
                    if (await CityPickerSheet.show(context)) {
                      await controller.onCityChosen();
                    }
                  },
          ),
        ],
        // A way past the notification step, in every state it can be in —
        // reminders are the only thing behind it. See
        // PermissionController.notificationStepSkippable for why this is iOS
        // only today.
        if (!isLocation && PermissionController.notificationStepSkippable) ...[
          const SizedBox(height: AtharSpace.xs),
          AtharButton(
            label: 'perm_notif_skip'.tr,
            variant: AtharButtonVariant.ghost,
            expand: true,
            onPressed: busy ? null : controller.skipNotifications,
          ),
        ],
      ],
    );
  }
}

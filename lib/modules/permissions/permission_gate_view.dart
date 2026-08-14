import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/permission_service.dart';
import 'permission_controller.dart';

/// Full-screen, brand-styled permission explanation + request UI. Rendered on
/// the fixed #15201A background regardless of the app's light/dark mode so the
/// gate always looks consistent and premium.
class PermissionGateView extends GetView<PermissionController> {
  const PermissionGateView({super.key});

  // Fixed brand tokens for the gate (see requirement: bg #15201A).
  static const _bg = Color(0xFF15201A);
  static const _surface = Color(0xFF243329);
  static const _textOn = Color(0xFFF1EDE4);
  static const _muted = Color(0xFF97A69C);
  static const _gold = Color(0xFFC8A95B);
  static const _primary = Color(0xFF2E9E74);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          final step = controller.step.value;
          final state = controller.state.value;
          final isLocation = step == PermStep.location;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const _BrandLogo(),
                const SizedBox(height: 8),
                _StepDots(activeIndex: isLocation ? 0 : 1),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IconBadge(
                        icon: isLocation
                            ? Icons.location_on_rounded
                            : Icons.notifications_active_rounded,
                      ),
                      const SizedBox(height: 36),
                      Text(
                        (isLocation ? 'perm_location_title' : 'perm_notif_title').tr,
                        textAlign: TextAlign.center,
                        style: _title(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (isLocation ? 'perm_location_msg' : 'perm_notif_msg').tr,
                        textAlign: TextAlign.center,
                        style: _body(context),
                      ),
                      _StateNote(state: state),
                    ],
                  ),
                ),
                _Actions(
                  isLocation: isLocation,
                  state: state,
                  busy: controller.busy.value,
                ),
                const SizedBox(height: 28),
              ],
            ),
          );
        }),
      ),
    );
  }

  static TextStyle _title(BuildContext context) =>
      (Theme.of(context).textTheme.headlineMedium ?? const TextStyle()).copyWith(
        color: _textOn,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      );

  static TextStyle _body(BuildContext context) =>
      (Theme.of(context).textTheme.bodyLarge ?? const TextStyle()).copyWith(
        color: _muted,
        height: 1.7,
      );

  // ── Sub-widgets ─────────────────────────────────────────────────

  static const _radius = 18.0;
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/logo.png',
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => const Text(
          'أثر',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: PermissionGateView._gold,
            fontFamily: 'Amiri',
          ),
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
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 2; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == activeIndex ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == activeIndex ? PermissionGateView._gold : PermissionGateView._surface,
                borderRadius: BorderRadius.circular(4),
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
      decoration: const BoxDecoration(
        color: PermissionGateView._surface,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: PermissionGateView._primary.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 44, color: PermissionGateView._gold),
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

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: PermissionGateView._gold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PermissionGateView._gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 20, color: PermissionGateView._gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                key.tr,
                style: const TextStyle(color: PermissionGateView._textOn, height: 1.5, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The action buttons, driven by the current permission [state].
class _Actions extends StatelessWidget {
  const _Actions({
    required this.isLocation,
    required this.state,
    required this.busy,
  });

  final bool isLocation;
  final PermState state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PermissionController>();
    final needsSettings = state.needsSettings || state == PermState.serviceDisabled;

    final primaryLabel = needsSettings
        ? 'perm_open_settings'.tr
        : (isLocation ? 'perm_location_cta' : 'perm_notif_cta').tr;

    final onPrimary = needsSettings ? controller.onOpenSettings : controller.onPrimaryAction;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(label: primaryLabel, busy: busy, onPressed: busy ? null : onPrimary),
        if (needsSettings) ...[
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'perm_try_again'.tr,
            onPressed: busy ? null : controller.onTryAgain,
          ),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: PermissionGateView._primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PermissionGateView._primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PermissionGateView._radius),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: PermissionGateView._textOn,
          side: const BorderSide(color: Color(0xFF33453A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PermissionGateView._radius),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

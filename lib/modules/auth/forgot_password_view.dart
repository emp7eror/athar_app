import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import 'forgot_password_controller.dart';

/// Three calm steps — email, code, new password — on one screen.
class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.step.value;
      return PopScope(
        // Back walks through the steps before leaving the screen.
        canPop: step == ResetStep.email,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.back();
        },
        child: Scaffold(
          appBar: AppBar(title: Text('forgot_password_title'.tr)),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StepIndicator(step: step),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                                  .animate(animation),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(step),
                            child: switch (step) {
                              ResetStep.email => const _EmailStep(),
                              ResetStep.code => const _CodeStep(),
                              ResetStep.password => const _PasswordStep(),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _EmailStep extends GetView<ForgotPasswordController> {
  const _EmailStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: Icons.lock_reset_rounded,
          title: 'reset_email_title'.tr,
          subtitle: 'reset_email_sub'.tr,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          textDirection: TextDirection.ltr,
          onSubmitted: (_) => controller.sendCode(),
          decoration: InputDecoration(
            hintText: 'email'.tr,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(label: 'reset_send_code'.tr, onPressed: controller.sendCode),
      ],
    );
  }
}

class _CodeStep extends GetView<ForgotPasswordController> {
  const _CodeStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          icon: Icons.mark_email_read_outlined,
          title: 'reset_code_title'.tr,
          subtitle: 'reset_code_sub'.trParams({'email': controller.email.text.trim()}),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller.code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLength: ForgotPasswordController.codeLength,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: context.text.headlineMedium?.copyWith(
            letterSpacing: 14,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          onChanged: (v) {
            // Six digits typed or pasted — check straight away.
            if (v.length == ForgotPasswordController.codeLength) controller.verifyCode();
          },
          onSubmitted: (_) => controller.verifyCode(),
          decoration: const InputDecoration(counterText: '', hintText: '••••••'),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(label: 'reset_verify'.tr, onPressed: controller.verifyCode),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: controller.changeEmail,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text('reset_change_email'.tr),
            ),
            Obx(() {
              final wait = controller.resendIn.value;
              return TextButton.icon(
                onPressed: wait > 0 || controller.loading.value ? null : controller.sendCode,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  wait > 0
                      ? 'reset_resend_in'.trParams({'seconds': '$wait'})
                      : 'reset_resend'.tr,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _PasswordStep extends GetView<ForgotPasswordController> {
  const _PasswordStep();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hidden = controller.obscure.value;
      final toggle = IconButton(
        onPressed: controller.toggleObscure,
        icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(
            icon: Icons.password_rounded,
            title: 'reset_new_title'.tr,
            subtitle: 'reset_new_sub'.tr,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller.password,
            obscureText: hidden,
            autofocus: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              hintText: 'reset_new_password'.tr,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: toggle,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.confirmation,
            obscureText: hidden,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => controller.savePassword(),
            decoration: InputDecoration(
              hintText: 'reset_confirm_password'.tr,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(label: 'reset_save'.tr, onPressed: controller.savePassword),
        ],
      );
    });
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: athar.gold.withValues(alpha: 0.14),
            border: Border.all(color: athar.gold.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 34, color: athar.gold),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: athar.textMuted, height: 1.6),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final ResetStep step;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final s in ResetStep.values) ...[
          if (s.index > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: s == step ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: s.index <= step.index ? athar.gold : athar.textMuted.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryButton extends GetView<ForgotPasswordController> {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.loading.value;
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.onPrimary),
                )
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    });
  }
}

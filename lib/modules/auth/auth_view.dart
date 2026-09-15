import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/ui/athar_ui.dart';
import '../../widgets/gender_selector.dart';
import 'auth_controller.dart';

/// Sign in, register, or carry on as a guest.
class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, AtharSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AtharIconButton(
                      icon: Icons.translate_rounded,
                      tooltip: 'language'.tr,
                      onPressed: Get.find<LocalizationController>().toggle,
                    ),
                  ),
                  const SizedBox(height: AtharSpace.sm),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AtharSpace.md),
                  Text('app_name'.tr, textAlign: TextAlign.center, style: context.text.headlineMedium),
                  const SizedBox(height: AtharSpace.xxs),
                  Text(
                    'brand_tagline'.tr,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AtharSpace.xl),
                  Obx(() {
                    final registering = controller.isRegister.value;
                    final busy = controller.loading.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (registering) ...[
                          TextField(
                            controller: controller.name,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'name'.tr,
                              prefixIcon: const Icon(Icons.person_rounded),
                            ),
                          ),
                          const SizedBox(height: AtharSpace.sm),
                          TextField(
                            controller: controller.age,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'age'.tr,
                              prefixIcon: const Icon(Icons.cake_rounded),
                            ),
                          ),
                          const SizedBox(height: AtharSpace.sm),
                          GenderSelector(
                            value: controller.gender.value,
                            onChanged: (v) => controller.gender.value = v,
                          ),
                          const SizedBox(height: AtharSpace.sm),
                        ],
                        TextField(
                          controller: controller.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: 'email'.tr,
                            prefixIcon: const Icon(Icons.alternate_email_rounded),
                          ),
                        ),
                        const SizedBox(height: AtharSpace.sm),
                        _PasswordField(controller: controller),
                        if (!registering)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: controller.openForgotPassword,
                              child: Text('forgot_password'.tr),
                            ),
                          ),
                        const SizedBox(height: AtharSpace.md),
                        AtharButton(
                          label: registering ? 'register'.tr : 'login'.tr,
                          expand: true,
                          loading: busy,
                          onPressed: controller.submit,
                        ),
                        const SizedBox(height: AtharSpace.xxs),
                        Center(
                          child: TextButton(
                            onPressed: controller.toggleMode,
                            child: Text(registering ? 'login'.tr : 'register'.tr),
                          ),
                        ),
                        const SizedBox(height: AtharSpace.xs),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AtharSpace.sm),
                              child: Text(
                                'or'.tr,
                                style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: AtharSpace.md),
                        AtharButton(
                          label: 'continue_as_guest'.tr,
                          icon: Icons.person_outline_rounded,
                          variant: AtharButtonVariant.secondary,
                          expand: true,
                          onPressed: busy ? null : controller.continueAsGuest,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The password field, with a show/hide toggle. The visibility is only ever a
/// property of this field, so it lives here rather than in the controller.
class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller});

  final AuthController controller;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller.password,
      obscureText: _hidden,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => widget.controller.submit(),
      decoration: InputDecoration(
        hintText: 'password'.tr,
        prefixIcon: const Icon(Icons.lock_rounded),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _hidden = !_hidden),
          tooltip: _hidden ? 'password_show'.tr : 'password_hide'.tr,
          icon: Icon(_hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localization_controller.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: Get.find<LocalizationController>().toggle,
                    child: const Text('AR / EN'),
                  ),
                ),
                Text('app_name'.tr,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 32),
                Obx(() => Column(children: [
                      if (controller.isRegister.value) ...[
                        _field(controller.name, 'name'.tr),
                        _field(controller.age, 'age'.tr, number: true),
                      ],
                      _field(controller.email, 'email'.tr),
                      _field(controller.password, 'password'.tr, obscure: true),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: controller.loading.value ? null : controller.submit,
                          child: controller.loading.value
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  controller.isRegister.value ? 'register'.tr : 'login'.tr,
                                  style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.toggleMode,
                        child: Text(controller.isRegister.value ? 'login'.tr : 'register'.tr),
                      ),
                      const SizedBox(height: 4),
                      // ── Divider ──
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('or'.tr,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 12)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // ── Continue as guest ──
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.loading.value
                              ? null
                              : controller.continueAsGuest,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          icon: const Icon(Icons.person_outline,
                              color: AppColors.primary),
                          label: Text('continue_as_guest'.tr,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool obscure = false, bool number = false}) {
    final colors = Theme.of(Get.context!).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: colors.onSurface),   // ← لون النص
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.onSurfaceVariant),  // ← لون الـ hint
        ),
      ),
    );
  }
}

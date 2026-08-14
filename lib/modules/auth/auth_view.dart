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
      backgroundColor: AppColors.bg,
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
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/error_reporter.dart';
import '../../core/utils/snackbar.dart';
import '../../data/providers/api_provider.dart';

enum ResetStep { email, code, password }

/// "Forgot password": email → 6-digit code from the email → new password.
///
/// Finishes with `Get.back(result: email)` so the login screen can fill the
/// address in for the user.
class ForgotPasswordController extends GetxController {
  ForgotPasswordController({String initialEmail = ''}) : _initialEmail = initialEmail;

  static const codeLength = 6;

  /// Mirrors the server's resend cooldown.
  static const resendCooldownSeconds = 60;

  final String _initialEmail;
  final _api = Get.find<ApiProvider>();

  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();

  final step = ResetStep.email.obs;
  final loading = false.obs;
  final resendIn = 0.obs;
  final obscure = true.obs;

  Timer? _resendTimer;

  String get _email => email.text.trim();

  @override
  void onInit() {
    super.onInit();
    email.text = _initialEmail;
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    email.dispose();
    code.dispose();
    password.dispose();
    confirmation.dispose();
    super.onClose();
  }

  // ── Steps ──────────────────────────────────────────────────────────

  /// Sends (or re-sends) the code and moves to the code step.
  Future<void> sendCode() async {
    if (loading.value || resendIn.value > 0 && step.value == ResetStep.code) return;
    if (!GetUtils.isEmail(_email)) {
      _error('reset_email_invalid'.tr);
      return;
    }

    await _run(() async {
      final res = await _api.forgotPassword(_email);
      code.clear();
      step.value = ResetStep.code;
      _startResendTimer((res['resend_after'] as num?)?.toInt() ?? resendCooldownSeconds);
      AppSnackbar.show('forgot_password_title'.tr, res['message']?.toString() ?? '');
    }, onApiError: (e) {
      // A code went to this address moments ago: carry on to entering it,
      // with the resend button counting down the time the server gave.
      if (e.reason == 'resend_wait') {
        step.value = ResetStep.code;
        _startResendTimer((e.data['retry_after'] as num?)?.toInt() ?? resendCooldownSeconds);
      }
    });
  }

  Future<void> verifyCode() async {
    if (loading.value) return;
    if (code.text.trim().length != codeLength) {
      _error('reset_code_invalid_length'.tr);
      return;
    }

    await _run(() async {
      await _api.verifyResetCode(_email, code.text.trim());
      step.value = ResetStep.password;
    }, onApiError: (e) {
      if (e.reason == 'too_many_attempts') code.clear();
    });
  }

  Future<void> savePassword() async {
    if (loading.value) return;
    if (password.text.isEmpty) {
      _error('reset_password_empty'.tr);
      return;
    }
    if (password.text != confirmation.text) {
      _error('reset_password_mismatch'.tr);
      return;
    }

    await _run(() async {
      await _api.resetPassword(
        email: _email,
        code: code.text.trim(),
        password: password.text,
        confirmation: confirmation.text,
      );
      // Reset loading before leaving: closing disposes the text controllers,
      // and a rebuild afterwards would read them.
      loading.value = false;
      Get.back(result: _email);
    }, onApiError: (e) {
      // The code expired or ran out of attempts meanwhile — back to the code
      // step to request a new one. Password rule errors keep the user here.
      if (e.reason == 'code_invalid' || e.reason == 'too_many_attempts') {
        code.clear();
        step.value = ResetStep.code;
      }
    });
  }

  /// Back one step; returns false when already on the first step.
  bool back() {
    switch (step.value) {
      case ResetStep.email:
        return false;
      case ResetStep.code:
        step.value = ResetStep.email;
      case ResetStep.password:
        step.value = ResetStep.code;
    }
    return true;
  }

  void changeEmail() => step.value = ResetStep.email;

  void toggleObscure() => obscure.toggle();

  // ── Helpers ────────────────────────────────────────────────────────

  Future<void> _run(
    Future<void> Function() action, {
    void Function(ApiException e)? onApiError,
  }) async {
    loading.value = true;
    try {
      await action();
    } on ApiException catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      _error(e.message);
      onApiError?.call(e);
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      _error('reset_network_error'.tr);
    } finally {
      if (!isClosed) loading.value = false;
    }
  }

  void _startResendTimer([int seconds = resendCooldownSeconds]) {
    _resendTimer?.cancel();
    resendIn.value = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (isClosed || resendIn.value <= 1) {
        resendIn.value = 0;
        t.cancel();
      } else {
        resendIn.value--;
      }
    });
  }

  void _error(String message) => AppSnackbar.error('forgot_password_title'.tr, message);
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../design/athar_tokens.dart';
import '../theme/app_theme.dart';
import 'athar_button.dart';
import 'athar_tone.dart';

/// Athar's dialog: an optional icon, a title, a short message and up to two
/// actions. Replaces bare AlertDialogs.
class AtharDialog extends StatelessWidget {
  const AtharDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.message,
    this.icon,
    this.tone = AtharTone.brand,
    this.cancelLabel,
    this.onCancel,
    this.destructive = false,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final AtharTone tone;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final iconTone = destructive ? AtharTone.danger : tone;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.lg),
      child: Padding(
        padding: const EdgeInsets.all(AtharSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: iconTone.background(context), shape: BoxShape.circle),
                child: Icon(icon, size: 28, color: iconTone.foreground(context)),
              ),
              const SizedBox(height: AtharSpace.md),
            ],
            Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
            if (message != null) ...[
              const SizedBox(height: AtharSpace.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AtharSpace.lg),
            Row(
              children: [
                if (cancelLabel != null) ...[
                  Expanded(
                    child: AtharButton(
                      label: cancelLabel!,
                      variant: AtharButtonVariant.secondary,
                      onPressed: onCancel,
                    ),
                  ),
                  const SizedBox(width: AtharSpace.sm),
                ],
                Expanded(
                  child: AtharButton(
                    label: confirmLabel,
                    variant: destructive ? AtharButtonVariant.danger : AtharButtonVariant.primary,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for confirmation; true only when confirmed.
Future<bool> showAtharConfirm({
  required String title,
  required String confirmLabel,
  String? message,
  String? cancelLabel,
  IconData? icon,
  bool destructive = false,
}) async {
  final confirmed = await Get.dialog<bool>(
    AtharDialog(
      title: title,
      message: message,
      icon: icon,
      destructive: destructive,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel ?? 'cancel'.tr,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    ),
  );
  return confirmed ?? false;
}

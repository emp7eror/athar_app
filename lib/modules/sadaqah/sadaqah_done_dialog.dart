import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';

/// Shown after a sadaqah is recorded — the same layout as the prayer's done
/// popup — with the points the server actually gave: the deed's own for the
/// day's first sadaqah, none after that.
class SadaqahDoneDialog extends StatelessWidget {
  const SadaqahDoneDialog._(this.pointsAwarded);

  final int pointsAwarded;

  static Future<void> show(int pointsAwarded) =>
      Get.dialog(SadaqahDoneDialog._(pointsAwarded), barrierDismissible: true);

  @override
  Widget build(BuildContext context) {
    final tone = AtharTone.brand;
    final message = pointsAwarded > 0
        ? 'sadaqah_done_points'.trParams({'points': '$pointsAwarded'})
        : 'sadaqah_done_no_points'.tr;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AtharSpace.md,
        vertical: AtharSpace.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AtharSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1),
                  duration: AtharMotion.emphasis,
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: tone.background(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      size: 34,
                      color: tone.foreground(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AtharSpace.md),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  'sadaqah_done_title'.tr,
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge,
                ),
              ),
              const SizedBox(height: AtharSpace.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AtharSpace.lg),
              AtharCard(
                tone: AtharCardTone.surface,
                child: Column(
                  children: [
                    Text(
                      'sadaqah_done_quote'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.titleMedium?.copyWith(height: 1.9),
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    Text(
                      'sadaqah_done_quote_ref'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.labelMedium?.copyWith(
                        color: tone.foreground(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AtharSpace.lg),
              AtharButton(
                label: 'prayer_done_ok'.tr,
                expand: true,
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

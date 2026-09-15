import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';

/// Post-completion feedback shown *after* a successful save.
///
/// Two variants share one layout:
///  * [showOnTime]      — success tone, congratulatory verse.
///  * [showOutsideTime] — gold tone, reflective verse and a gentle note.
class PrayerDoneDialog extends StatelessWidget {
  final String titleKey;
  final String verseKey;
  final String referenceKey;
  final String? messageKey; // extra line (only used for the outside-time variant)
  final bool outsideTime;

  const PrayerDoneDialog._({
    required this.titleKey,
    required this.verseKey,
    required this.referenceKey,
    required this.outsideTime,
    this.messageKey,
  });

  static Future<void> showOnTime() => Get.dialog(
        const PrayerDoneDialog._(
          titleKey: 'prayer_done_on_time_title',
          verseKey: 'prayer_done_on_time_verse',
          referenceKey: 'prayer_done_on_time_ref',
          outsideTime: false,
        ),
        barrierDismissible: true,
      );

  static Future<void> showOutsideTime() => Get.dialog(
        const PrayerDoneDialog._(
          titleKey: 'prayer_done_late_title',
          verseKey: 'prayer_done_late_verse',
          referenceKey: 'prayer_done_late_ref',
          messageKey: 'prayer_done_late_msg',
          outsideTime: true,
        ),
        barrierDismissible: true,
      );

  @override
  Widget build(BuildContext context) {
    final tone = outsideTime ? AtharTone.gold : AtharTone.success;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.lg),
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
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: tone.background(context), shape: BoxShape.circle),
                    child: Icon(
                      outsideTime ? Icons.schedule_rounded : Icons.check_circle_rounded,
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
                child: Text(titleKey.tr, textAlign: TextAlign.center, style: context.text.titleLarge),
              ),
              if (messageKey != null) ...[
                const SizedBox(height: AtharSpace.xs),
                Text(
                  messageKey!.tr,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AtharSpace.lg),
              AtharCard(
                tone: AtharCardTone.surface,
                child: Column(
                  children: [
                    Text(
                      verseKey.tr,
                      textAlign: TextAlign.center,
                      style: context.text.titleMedium?.copyWith(height: 1.9),
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    Text(
                      referenceKey.tr,
                      textAlign: TextAlign.center,
                      style: context.text.labelMedium?.copyWith(color: tone.foreground(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AtharSpace.lg),
              AtharButton(label: 'prayer_done_ok'.tr, expand: true, onPressed: () => Get.back()),
            ],
          ),
        ),
      ),
    );
  }
}

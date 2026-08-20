import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';

/// Post-completion feedback popup shown *after* a successful API save.
///
/// Two visual variants share the same layout so both feel like one component:
///  * [showOnTime]      — success-tinted, congratulatory verse.
///  * [showOutsideTime] — gold/warning-tinted, reflective verse + du'a.
///
/// All copy is translated; nothing user-facing is hardcoded here.
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
    final athar = context.athar;
    // Success (sage/green) for on-time, gold (warm/reflective) for late.
    final accent = outsideTime ? athar.gold : athar.success;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: athar.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: accent.withValues(alpha: 0.25), width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    verseKey.tr,
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium?.copyWith(
                      height: 1.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    referenceKey.tr,
                    textAlign: TextAlign.center,
                    style: context.text.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Verse ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, athar.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    outsideTime
                        ? Icons.access_time_rounded
                        : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titleKey.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Extra message (outside-time only) ──
            if (messageKey != null) ...[
              const SizedBox(height: 16),
              Text(
                messageKey!.tr,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: athar.textMuted,
                  height: 1.6,
                ),
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'prayer_done_ok'.tr,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

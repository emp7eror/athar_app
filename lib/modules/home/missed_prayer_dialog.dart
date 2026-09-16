import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'prayer_dialog_parts.dart';

/// Predefined reasons the user can pick for missing a prayer, sent to the API
/// as a stable snake_case value (see [MissedReasonX.apiValue]).
///
/// [forgotToMark] is different in kind from the others: the prayer *was*
/// performed on time, the user just didn't record it in the app. It's logged
/// as an on-time prayer — so no late halving — but earns no on-time bonus
/// either, since punctuality can't be verified after the fact.
enum MissedReason { asleep, forgot, busy, traveling, sick, lazy, occasion, forgotToMark }

extension MissedReasonX on MissedReason {
  /// Wire value. `name` would send camelCase for [forgotToMark].
  String get apiValue => switch (this) {
        MissedReason.forgotToMark => 'forgot_to_mark',
        _ => name,
      };

  /// True when the prayer was performed within its window and only the
  /// *logging* happened late.
  bool get prayedOnTime => this == MissedReason.forgotToMark;

  String get labelKey => switch (this) {
        MissedReason.asleep => 'reason_asleep',
        MissedReason.forgot => 'reason_forgot',
        MissedReason.busy => 'reason_busy',
        MissedReason.traveling => 'reason_traveling',
        MissedReason.sick => 'reason_sick',
        MissedReason.lazy => 'reason_lazy',
        MissedReason.occasion => 'reason_occasion',
        MissedReason.forgotToMark => 'reason_forgot_to_mark',
      };

  IconData get icon => switch (this) {
        MissedReason.asleep => Icons.bedtime_rounded,
        MissedReason.forgot => Icons.psychology_alt_rounded,
        MissedReason.busy => Icons.work_rounded,
        MissedReason.traveling => Icons.flight_rounded,
        MissedReason.sick => Icons.healing_rounded,
        MissedReason.lazy => Icons.weekend_rounded,
        MissedReason.occasion => Icons.celebration_rounded,
        MissedReason.forgotToMark => Icons.edit_note_rounded,
      };
}

/// Result of the missed-prayer confirmation flow.
class MissedPrayerResult {
  final MissedReason reason;
  final String note;
  const MissedPrayerResult({required this.reason, required this.note});
}

/// Modal shown when the user chooses to log a prayer whose scheduled window
/// has already closed.
class MissedPrayerDialog extends StatefulWidget {
  final String prayerName;

  /// The "forgot to log it" allowance is one per day (enforced server-side);
  /// hidden here once spent so the user isn't rejected after choosing it.
  final bool allowForgotToMark;

  const MissedPrayerDialog({
    super.key,
    required this.prayerName,
    this.allowForgotToMark = true,
  });

  static Future<MissedPrayerResult?> show(
    String prayerName, {
    bool allowForgotToMark = true,
  }) {
    return Get.dialog<MissedPrayerResult>(
      MissedPrayerDialog(
        prayerName: prayerName,
        allowForgotToMark: allowForgotToMark,
      ),
      barrierDismissible: false,
    );
  }

  @override
  State<MissedPrayerDialog> createState() => _MissedPrayerDialogState();
}

class _MissedPrayerDialogState extends State<MissedPrayerDialog> {
  MissedReason? _reason;
  final _noteCtrl = TextEditingController();
  bool _showReasonError = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_reason == null) {
      setState(() => _showReasonError = true);
      return;
    }
    Get.back(
      result: MissedPrayerResult(
        reason: _reason!,
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reasons = [
      for (final r in MissedReason.values)
        if (r != MissedReason.forgotToMark || widget.allowForgotToMark) r,
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrayerDialogHeader(
              icon: Icons.history_rounded,
              tone: AtharTone.brand,
              title: 'missed_prayer_title'.tr,
              badge: AtharBadge(label: widget.prayerName.tr, tone: AtharTone.brand),
              subtitle: 'missed_prayer_desc'.tr,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.xs, AtharSpace.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrayerQuestion<MissedReason>(
                      label: 'missed_reason_label'.tr,
                      showError: _showReasonError,
                      errorText: 'missed_reason_required'.tr,
                      options: reasons,
                      labels: [for (final r in reasons) r.labelKey.tr],
                      icons: [for (final r in reasons) r.icon],
                      selected: _reason,
                      onSelected: (v) => setState(() {
                        _reason = v;
                        _showReasonError = false;
                      }),
                    ),
                    // Praying on time but logging it late is treated as an
                    // on-time prayer — worth saying so the choice is meaningful.
                    AnimatedSize(
                      duration: AtharMotion.base,
                      curve: AtharMotion.standard,
                      alignment: AlignmentDirectional.topStart,
                      child: _reason?.prayedOnTime == true
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: AtharSpace.lg),
                              child: AtharCard(
                                tone: AtharCardTone.surface,
                                padding: const EdgeInsets.all(AtharSpace.sm),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_rounded, size: AtharSize.icon, color: context.colors.primary),
                                    const SizedBox(width: AtharSpace.xs),
                                    Expanded(
                                      child: Text(
                                        'reason_forgot_to_mark_hint'.tr,
                                        style: context.text.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
            PrayerDialogActions(
              confirmLabel: 'confirm'.tr,
              ready: _reason != null,
              onConfirm: _submit,
              onCancel: () => Get.back(result: null),
            ),
          ],
        ),
      ),
    );
  }
}

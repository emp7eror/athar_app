import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/choice_chip_group.dart';

/// Predefined reasons the user can pick for missing a prayer, sent to the API
/// as a stable snake_case value (see [MissedReasonX.apiValue]).
///
/// [forgotToMark] is different in kind from the others: the prayer *was*
/// performed on time, the user just didn't record it in the app. It's logged
/// as an on-time prayer — so no late halving — but earns no on-time bonus
/// either, since punctuality can't be verified after the fact.
enum MissedReason { asleep, forgot, busy, traveling, forgotToMark }

extension MissedReasonX on MissedReason {
  /// Wire value. `name` would send camelCase for [forgotToMark].
  String get apiValue => switch (this) {
        MissedReason.forgotToMark => 'forgot_to_mark',
        _ => name,
      };

  /// True when the prayer was performed within its window and only the
  /// *logging* happened late.
  bool get prayedOnTime => this == MissedReason.forgotToMark;
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
    final athar = context.athar;
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [athar.gold, athar.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_toggle_off_rounded,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('missed_prayer_title'.tr,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(widget.prayerName.tr,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text('missed_prayer_desc'.tr,
                style: TextStyle(fontSize: 13, color: athar.textMuted)),
            const SizedBox(height: 20),

            // ── Reason (required, chip group like mood) ──
            _Label(text: 'missed_reason_label'.tr, required: true),
            const SizedBox(height: 10),
            ChoiceChipGroup<MissedReason>(
              options: [
                MissedReason.asleep,
                MissedReason.forgot,
                MissedReason.busy,
                MissedReason.traveling,
                if (widget.allowForgotToMark) MissedReason.forgotToMark,
              ],
              labels: [
                'reason_asleep'.tr,
                'reason_forgot'.tr,
                'reason_busy'.tr,
                'reason_traveling'.tr,
                if (widget.allowForgotToMark) 'reason_forgot_to_mark'.tr,
              ],
              emojis: [
                '😴',
                '🤔',
                '💼',
                '✈️',
                if (widget.allowForgotToMark) '📝',
              ],
              selected: _reason,
              onSelected: (v) => setState(() {
                _reason = v;
                _showReasonError = false;
              }),
            ),
            // Praying on time but logging it late is treated as an on-time
            // prayer — worth telling the user so the choice is meaningful.
            if (_reason?.prayedOnTime == true) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 15, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('reason_forgot_to_mark_hint'.tr,
                        style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              ),
            ],
            if (_showReasonError) ...[
              const SizedBox(height: 6),
              Text('missed_reason_required'.tr,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error)),
            ],

            const SizedBox(height: 20),

            // ── Note (optional) ──
            _Label(text: 'missed_note_label'.tr, required: false),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(hintText: 'missed_note_hint'.tr),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: athar.textMuted),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('cancel'.tr,
                        style: TextStyle(
                            color: athar.textMuted,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('confirm'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
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

class _Label extends StatelessWidget {
  final String text;
  final bool required;
  const _Label({required this.text, required this.required});

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    return Row(
      children: [
        Text(text,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: athar.textMuted)),
        if (required)
          Text(' *',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 14)),
      ],
    );
  }
}

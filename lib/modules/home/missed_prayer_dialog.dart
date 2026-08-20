import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Predefined reasons the user can pick for missing a prayer. Sent to the API
/// as the enum's `name` (e.g. "asleep") for a stable, translatable value.
enum MissedReason { asleep, forgot, busy, traveling }

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
  const MissedPrayerDialog({super.key, required this.prayerName});

  static Future<MissedPrayerResult?> show(String prayerName) {
    return Get.dialog<MissedPrayerResult>(
      MissedPrayerDialog(prayerName: prayerName),
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
            _ChipGroup<MissedReason>(
              options: const [
                MissedReason.asleep,
                MissedReason.forgot,
                MissedReason.busy,
                MissedReason.traveling,
              ],
              labels: [
                'reason_asleep'.tr,
                'reason_forgot'.tr,
                'reason_busy'.tr,
                'reason_traveling'.tr,
              ],
              emojis: const ['😴', '🤔', '💼', '✈️'],
              selected: _reason,
              onSelected: (v) => setState(() {
                _reason = v;
                _showReasonError = false;
              }),
            ),
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

// Chip group mirroring the visual language used by PrayerConfirmDialog's
// difficulty / mood pickers.
class _ChipGroup<T> extends StatelessWidget {
  final List<T> options;
  final List<String> labels;
  final List<String> emojis;
  final T? selected;
  final void Function(T) onSelected;

  const _ChipGroup({
    required this.options,
    required this.labels,
    required this.emojis,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 3,
        runSpacing: 5,
        children: List.generate(options.length, (i) {
          final isSelected = options[i] == selected;
          return ChoiceChip(
            label: Text('${emojis[i]}  ${labels[i]}'),
            selected: isSelected,
            onSelected: (_) => onSelected(options[i]),
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundColor: AppColors.bg,
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );
        }),
      );
}

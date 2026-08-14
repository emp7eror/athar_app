import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';

// ── نماذج الإدخال ──────────────────────────────────────────────
enum PrayerDifficulty { easy, medium, hard }
enum PrayerMood       { focused, distracted, tired, peaceful }

class PrayerConfirmResult {
  final PrayerDifficulty difficulty;
  final PrayerMood       mood;
  final String           note;

  const PrayerConfirmResult({
    required this.difficulty,
    required this.mood,
    required this.note,
  });
}

// ── الـ Dialog ──────────────────────────────────────────────────
class PrayerConfirmDialog extends StatefulWidget {
  final String prayerName;
  final int    points;

  const PrayerConfirmDialog({
    super.key,
    required this.prayerName,
    required this.points,
  });

  /// يعرض الـ dialog ويُعيد النتيجة أو null إن ألغى المستخدم.
  static Future<PrayerConfirmResult?> show(String prayerName, int points) {
    return Get.dialog<PrayerConfirmResult>(
      PrayerConfirmDialog(prayerName: prayerName, points: points),
      barrierDismissible: false,
    );
  }

  @override
  State<PrayerConfirmDialog> createState() => _PrayerConfirmDialogState();
}

class _PrayerConfirmDialogState extends State<PrayerConfirmDialog> {
  PrayerDifficulty _difficulty = PrayerDifficulty.easy;
  PrayerMood       _mood       = PrayerMood.focused;
  final _noteCtrl              = TextEditingController();

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  // ── ترجمة الخيارات ─────────────────────────────────────────
  String get _difficultyLabel => switch (_difficulty) {
    PrayerDifficulty.easy   => 'difficulty_easy'.tr,
    PrayerDifficulty.medium => 'difficulty_medium'.tr,
    PrayerDifficulty.hard   => 'difficulty_hard'.tr,
  };

  String get _moodLabel => switch (_mood) {
    PrayerMood.focused    => 'mood_focused'.tr,
    PrayerMood.distracted => 'mood_distracted'.tr,
    PrayerMood.tired      => 'mood_tired'.tr,
    PrayerMood.peaceful   => 'mood_peaceful'.tr,
  };

  // ── بناء الواجهة ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── رأس الـ dialog ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('🕌', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.prayerName.tr,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text('+${widget.points} ${'points'.tr}',
                            style: const TextStyle(
                                color: AppColors.accent, fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── الصعوبة ──
            _SectionLabel(label: 'prayer_difficulty'.tr),
            const SizedBox(height: 10),
            _ChipGroup<PrayerDifficulty>(
              options: const [
                PrayerDifficulty.easy,
                PrayerDifficulty.medium,
                PrayerDifficulty.hard,
              ],
              labels: [
                'difficulty_easy'.tr,
                'difficulty_medium'.tr,
                'difficulty_hard'.tr,
              ],
              emojis: const ['😊', '😐', '😓'],
              selected: _difficulty,
              onSelected: (v) => setState(() => _difficulty = v),
            ),

            const SizedBox(height: 20),

            // ── الحالة النفسية ──
            _SectionLabel(label: 'prayer_mood'.tr),
            const SizedBox(height: 10),
            _ChipGroup<PrayerMood>(
              options: const [
                PrayerMood.focused,
                PrayerMood.peaceful,
                PrayerMood.distracted,
                PrayerMood.tired,
              ],
              labels: [
                'mood_focused'.tr,
                'mood_peaceful'.tr,
                'mood_distracted'.tr,
                'mood_tired'.tr,
              ],
              emojis: const ['🎯', '🌿', '💭', '😴'],
              selected: _mood,
              onSelected: (v) => setState(() => _mood = v),
            ),

            const SizedBox(height: 20),

            // ── ملاحظة اختيارية ──
            _SectionLabel(label: 'prayer_note'.tr),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 120,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'prayer_note_hint'.tr,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                counterStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),

            const SizedBox(height: 24),

            // ── الأزرار ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.textMuted),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('cancel'.tr,
                        style: const TextStyle(color: AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Get.back(
                      result: PrayerConfirmResult(
                        difficulty: _difficulty,
                        mood:       _mood,
                        note:       _noteCtrl.text.trim(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('confirm_prayer'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w800,
                            fontSize: 15)),
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

// ── Widgets مساعدة ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: AppColors.textMuted),
  );
}

class _ChipGroup<T> extends StatelessWidget {
  final List<T>      options;
  final List<String> labels;
  final List<String> emojis;
  final T            selected;
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
    spacing: 3, runSpacing: 5,
    children: List.generate(options.length, (i) {
      final isSelected = options[i] == selected;
      return ChoiceChip(
        label: Text('${emojis[i]}  ${labels[i]}'),
        selected: isSelected,
        onSelected: (_) => onSelected(options[i]),
        selectedColor: AppColors.primary.withOpacity(0.15),
        backgroundColor: AppColors.bg,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textMuted,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      );
    }),
  );
}
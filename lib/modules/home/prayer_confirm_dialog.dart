import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/choice_chip_group.dart';

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


  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      // Card surface (theme-aware) rather than a fixed dark emerald — the
      // chips/field/buttons below all assume a normal surface, and matches
      // MissedPrayerDialog so the two flows look like siblings.
      backgroundColor: athar.card,
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
                gradient: athar.heroGradient,
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
                            style: TextStyle(
                                color: athar.gold, fontSize: 13,
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
            ChoiceChipGroup<PrayerDifficulty>(
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
            ChoiceChipGroup<PrayerMood>(
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
                filled: true,
                fillColor: athar.beige,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                counterStyle:
                TextStyle(color: athar.textMuted, fontSize: 12),
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
                      side: BorderSide(color: athar.textMuted),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('cancel'.tr,
                        style: TextStyle(color: athar.textMuted,
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
    style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: context.athar.textMuted),
  );
}
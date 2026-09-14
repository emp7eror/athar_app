import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/choice_chip_group.dart';

// ── نماذج الإدخال ──────────────────────────────────────────────
enum PrayerDifficulty { easy, medium, hard }
enum PrayerMood       { focused, distracted, tired, peaceful }

/// Where the prayer was performed. Sent as its name.
enum PrayerPlace { mosque, home, work, other }

/// Prayed in congregation or alone. Sent as its name.
enum PrayerCongregation { jamaah, alone }

class PrayerConfirmResult {
  final PrayerDifficulty   difficulty;
  final PrayerMood         mood;
  final PrayerPlace        place;
  final PrayerCongregation congregation;
  final String note;

  const PrayerConfirmResult({
    required this.difficulty,
    required this.mood,
    required this.place,
    required this.congregation,
    required this.note,
  });
}

// ── الـ Dialog ──────────────────────────────────────────────────
/// Confirms an on-time prayer. Nothing is pre-selected: every question has to
/// be answered on purpose, so the analytics reflect what really happened
/// rather than whatever was selected by default.
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
  PrayerDifficulty?   _difficulty;
  PrayerMood?         _mood;
  PrayerPlace?        _place;
  PrayerCongregation? _congregation;
  final _noteCtrl = TextEditingController();

  /// Set after a confirm attempt with unanswered questions, so each one shows
  /// its own "choose an answer" line.
  bool _showErrors = false;

  bool get _complete =>
      _difficulty != null && _mood != null && _place != null && _congregation != null;

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_complete) {
      setState(() => _showErrors = true);
      return;
    }
    Get.back(
      result: PrayerConfirmResult(
        difficulty:   _difficulty!,
        mood:         _mood!,
        place:        _place!,
        congregation: _congregation!,
        note:         _noteCtrl.text.trim(),
      ),
    );
  }

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

            const SizedBox(height: 12),
            Text('prayer_required_hint'.tr,
                style: TextStyle(fontSize: 12.5, color: athar.textMuted)),
            const SizedBox(height: 20),

            // ── أين صليت؟ ──
            _Question<PrayerPlace>(
              label: 'prayer_place'.tr,
              showError: _showErrors && _place == null,
              options: PrayerPlace.values,
              labels: [
                'place_mosque'.tr,
                'place_home'.tr,
                'place_work'.tr,
                'place_other'.tr,
              ],
              emojis: const ['🕌', '🏠', '💼', '📍'],
              selected: _place,
              onSelected: (v) => setState(() => _place = v),
            ),

            // ── جماعة أم منفردًا؟ ──
            _Question<PrayerCongregation>(
              label: 'prayer_congregation'.tr,
              showError: _showErrors && _congregation == null,
              options: PrayerCongregation.values,
              labels: [
                'congregation_jamaah'.tr,
                'congregation_alone'.tr,
              ],
              emojis: const ['👥', '🧍'],
              selected: _congregation,
              onSelected: (v) => setState(() => _congregation = v),
            ),

            // ── الحالة النفسية ──
            _Question<PrayerMood>(
              label: 'prayer_mood'.tr,
              showError: _showErrors && _mood == null,
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

            // ── الصعوبة ──
            _Question<PrayerDifficulty>(
              label: 'prayer_difficulty'.tr,
              showError: _showErrors && _difficulty == null,
              options: PrayerDifficulty.values,
              labels: [
                'difficulty_easy'.tr,
                'difficulty_medium'.tr,
                'difficulty_hard'.tr,
              ],
              emojis: const ['😊', '😐', '😓'],
              selected: _difficulty,
              onSelected: (v) => setState(() => _difficulty = v),
            ),

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
                  child: AnimatedOpacity(
                    // Looks unavailable until everything is answered, but stays
                    // tappable so a tap can point out what's missing.
                    opacity: _complete ? 1 : 0.55,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      onPressed: _submit,
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

/// One required single-choice question: label with a red asterisk, the chips,
/// and a "choose an answer" line when it was skipped.
class _Question<T> extends StatelessWidget {
  const _Question({
    required this.label,
    required this.showError,
    required this.options,
    required this.labels,
    required this.emojis,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool showError;
  final List<T> options;
  final List<String> labels;
  final List<String> emojis;
  final T? selected;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(child: _SectionLabel(label: label)),
              Text(' *', style: TextStyle(color: error, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ChoiceChipGroup<T>(
            options: options,
            labels: labels,
            emojis: emojis,
            selected: selected,
            onSelected: onSelected,
          ),
          if (showError) ...[
            const SizedBox(height: 6),
            Text('prayer_choice_required'.tr,
                style: TextStyle(fontSize: 12, color: error)),
          ],
        ],
      ),
    );
  }
}

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

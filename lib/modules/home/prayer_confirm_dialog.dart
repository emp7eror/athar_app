import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'prayer_dialog_parts.dart';

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

  /// Shows the dialog; resolves to the answers, or null when cancelled.
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
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrayerDialogHeader(
              icon: Icons.mosque_rounded,
              title: widget.prayerName.tr,
              badge: AtharBadge(
                label: '+${widget.points} ${'points'.tr}',
                icon: Icons.star_rounded,
                tone: AtharTone.gold,
              ),
              subtitle: 'prayer_required_hint'.tr,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.xs, AtharSpace.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrayerQuestion<PrayerPlace>(
                      label: 'prayer_place'.tr,
                      showError: _showErrors && _place == null,
                      options: PrayerPlace.values,
                      labels: [
                        'place_mosque'.tr,
                        'place_home'.tr,
                        'place_work'.tr,
                        'place_other'.tr,
                      ],
                      icons: const [
                        Icons.mosque_rounded,
                        Icons.home_rounded,
                        Icons.work_rounded,
                        Icons.place_rounded,
                      ],
                      selected: _place,
                      onSelected: (v) => setState(() => _place = v),
                    ),
                    PrayerQuestion<PrayerCongregation>(
                      label: 'prayer_congregation'.tr,
                      showError: _showErrors && _congregation == null,
                      options: PrayerCongregation.values,
                      labels: [
                        'congregation_jamaah'.tr,
                        'congregation_alone'.tr,
                      ],
                      icons: const [
                        Icons.groups_rounded,
                        Icons.person_rounded,
                      ],
                      selected: _congregation,
                      onSelected: (v) => setState(() => _congregation = v),
                    ),
                    PrayerQuestion<PrayerMood>(
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
                      icons: const [
                        Icons.center_focus_strong_rounded,
                        Icons.spa_rounded,
                        Icons.bubble_chart_rounded,
                        Icons.bedtime_rounded,
                      ],
                      selected: _mood,
                      onSelected: (v) => setState(() => _mood = v),
                    ),
                    PrayerQuestion<PrayerDifficulty>(
                      label: 'prayer_difficulty'.tr,
                      showError: _showErrors && _difficulty == null,
                      options: PrayerDifficulty.values,
                      labels: [
                        'difficulty_easy'.tr,
                        'difficulty_medium'.tr,
                        'difficulty_hard'.tr,
                      ],
                      icons: const [
                        Icons.sentiment_satisfied_rounded,
                        Icons.sentiment_neutral_rounded,
                        Icons.sentiment_dissatisfied_rounded,
                      ],
                      selected: _difficulty,
                      onSelected: (v) => setState(() => _difficulty = v),
                    ),
                  ],
                ),
              ),
            ),
            PrayerDialogActions(
              confirmLabel: 'confirm_prayer'.tr,
              ready: _complete,
              onConfirm: _submit,
              onCancel: () => Get.back(result: null),
            ),
          ],
        ),
      ),
    );
  }
}

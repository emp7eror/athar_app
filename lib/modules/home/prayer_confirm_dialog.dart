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

/// Confirms an on-time prayer.
///
/// Every question opens on its most common answer, so logging a prayer is one
/// tap: confirm, or correct what differs. The defaults deliberately claim the
/// least — home, alone — because those feed `mosque_rate` and
/// `congregation_rate` in the stats and the coach, and a default that
/// over-claims would quietly inflate them.
class PrayerConfirmDialog extends StatefulWidget {
  final String prayerName;
  final int    points;

  /// Extra points for praying in congregation, shown on that choice and added
  /// to the badge while it is selected. The server decides the real award.
  final int    jamaahBonus;

  const PrayerConfirmDialog({
    super.key,
    required this.prayerName,
    required this.points,
    this.jamaahBonus = 0,
  });

  /// Shows the dialog; resolves to the answers, or null when cancelled.
  static Future<PrayerConfirmResult?> show(String prayerName, int points, {int jamaahBonus = 0}) {
    return Get.dialog<PrayerConfirmResult>(
      PrayerConfirmDialog(prayerName: prayerName, points: points, jamaahBonus: jamaahBonus),
      barrierDismissible: false,
    );
  }

  @override
  State<PrayerConfirmDialog> createState() => _PrayerConfirmDialogState();
}

class _PrayerConfirmDialogState extends State<PrayerConfirmDialog> {
  PrayerDifficulty   _difficulty   = PrayerDifficulty.easy;
  PrayerMood         _mood         = PrayerMood.focused;
  PrayerPlace        _place        = PrayerPlace.home;
  PrayerCongregation _congregation = PrayerCongregation.alone;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  /// What confirming would earn with the answers as they stand.
  int get _points =>
      widget.points + (_congregation == PrayerCongregation.jamaah ? widget.jamaahBonus : 0);

  void _submit() {
    Get.back(
      result: PrayerConfirmResult(
        difficulty:   _difficulty,
        mood:         _mood,
        place:        _place,
        congregation: _congregation,
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
                label: '+$_points ${'points'.tr}',
                icon: Icons.star_rounded,
                tone: AtharTone.gold,
              ),
              subtitle: 'prayer_answers_hint'.tr,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.xs, AtharSpace.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrayerQuestion<PrayerPlace>(
                      label: 'prayer_place'.tr,
                      required: false,
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
                      required: false,
                      options: PrayerCongregation.values,
                      labels: [
                        // The bonus is named on the choice that earns it.
                        widget.jamaahBonus > 0
                            ? 'congregation_jamaah_bonus'.trParams({'points': '${widget.jamaahBonus}'})
                            : 'congregation_jamaah'.tr,
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
                      required: false,
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
                      required: false,
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
              ready: true,
              onConfirm: _submit,
              onCancel: () => Get.back(result: null),
            ),
          ],
        ),
      ),
    );
  }
}

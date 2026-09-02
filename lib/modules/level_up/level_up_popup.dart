import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/widget_image_exporter.dart';
import '../../data/models/user_model.dart';
import '../../widgets/framed_avatar.dart';
import 'achievement_card.dart';

/// Full-screen "you've been promoted" celebration. Shown once per level
/// promotion by [HomeController]'s duplicate guard — this widget itself makes
/// no assumption about how many times it's invoked, it just renders one
/// celebration and resolves when the user continues.
class LevelUpPopup {
  /// Displays the popup and resolves once the user dismisses it (Continue,
  /// or after a share action completes and they return).
  static Future<void> show({
    required String name,
    required String? avatarUrl,
    required LevelInfo newLevel,
    required int totalPoints,
  }) {
    return Get.dialog(
      _LevelUpPopupBody(
        name: name,
        avatarUrl: avatarUrl,
        newLevel: newLevel,
        totalPoints: totalPoints,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black87,
    );
  }
}

class _LevelUpPopupBody extends StatefulWidget {
  const _LevelUpPopupBody({
    required this.name,
    required this.avatarUrl,
    required this.newLevel,
    required this.totalPoints,
  });

  final String name;
  final String? avatarUrl;
  final LevelInfo newLevel;
  final int totalPoints;

  @override
  State<_LevelUpPopupBody> createState() => _LevelUpPopupBodyState();
}

class _LevelUpPopupBodyState extends State<_LevelUpPopupBody> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 3));
  final _cardKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final path = await WidgetImageExporter.captureToFile(
        _cardKey,
        filename: 'athar_level_${widget.newLevel.level}.png',
      );
      if (path != null) {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(path)],
          text: 'share_achievement_text'.trParams({
            'level': widget.newLevel.displayName(Get.locale?.languageCode == 'ar'),
          }),
        ));
      }
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    final palette = AtharPalette.dark;

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Islamic-themed premium chrome: emerald/gold gradient backdrop.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryDark, palette.beige],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 28,
                gravity: 0.35,
                colors: const [
                  AppColors.secondary,
                  Colors.white,
                  AppColors.sage,
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.secondary, width: 2),
                      ),
                      child: FramedAvatar(
                        name: widget.name,
                        avatarUrl: widget.avatarUrl,
                        frameAsset: widget.newLevel.frame,
                        radius: 56,
                        backgroundColor: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'level_up_title'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'level_up_subtitle'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.newLevel.displayName(isAr),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'level_up_message'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _sharing ? null : _share,
                            icon: _sharing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white70))
                                : const Icon(Icons.share_rounded, color: Colors.white),
                            label: Text('share_achievement'.tr,
                                style: const TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('continue_btn'.tr,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Off-screen render target for the shareable card — laid out and
            // painted (so RepaintBoundary can capture it) but outside the
            // visible viewport.
            Positioned(
              left: -2000,
              top: 0,
              child: RepaintBoundary(
                key: _cardKey,
                child: AchievementCard(
                  name: widget.name,
                  avatarUrl: widget.avatarUrl,
                  newLevel: widget.newLevel,
                  totalPoints: widget.totalPoints,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

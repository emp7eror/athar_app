import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ui/athar_ui.dart';
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
  /// Displays the popup and resolves once the user dismisses it (Continue, or
  /// after a share action completes and they return).
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
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 3));
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
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'share_achievement_text'.trParams({
              'level': widget.newLevel.displayName(Get.locale?.languageCode == 'ar'),
            }),
          ),
        );
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
    final athar = context.athar;
    const onBrand = Colors.white;

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The brand ground, deep at the top and warmer toward the bottom.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [athar.brand, athar.primaryDark],
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
                colors: [athar.gold, Colors.white, athar.sage],
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AtharSpace.xxs + 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: athar.gold, width: 2),
                      ),
                      child: FramedAvatar(
                        name: widget.name,
                        avatarUrl: widget.avatarUrl,
                        frameAsset: widget.newLevel.frame,
                        level: widget.newLevel.level,
                        radius: 48,
                        backgroundColor: athar.gold,
                      ),
                    ),
                    const SizedBox(height: AtharSpace.lg),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        'level_up_title'.tr,
                        textAlign: TextAlign.center,
                        style: context.text.headlineLarge?.copyWith(color: onBrand),
                      ),
                    ),
                    const SizedBox(height: AtharSpace.xxs),
                    Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge?.copyWith(color: onBrand.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: AtharSpace.lg),
                    Text(
                      'level_up_subtitle'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: onBrand.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: AtharSpace.xxs),
                    Text(
                      widget.newLevel.displayName(isAr),
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(color: athar.gold),
                    ),
                    const SizedBox(height: AtharSpace.lg),
                    Text(
                      'level_up_message'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: onBrand.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: AtharSpace.xl),
                    Row(
                      children: [
                        Expanded(
                          child: _OnBrandButton(
                            label: 'share_achievement'.tr,
                            icon: Icons.share_rounded,
                            loading: _sharing,
                            onPressed: _share,
                          ),
                        ),
                        const SizedBox(width: AtharSpace.sm),
                        Expanded(
                          child: _GoldButton(label: 'continue_btn'.tr, onPressed: () => Get.back()),
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

/// An outlined action on the celebration's dark ground.
class _OnBrandButton extends StatelessWidget {
  const _OnBrandButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            )
          : Icon(icon, color: Colors.white),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md),
      ),
    );
  }
}

/// The gold confirm on the celebration's dark ground.
class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: context.athar.gold,
        foregroundColor: const Color(0xFF231A05),
        minimumSize: const Size(64, 52),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

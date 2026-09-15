import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ui/athar_ui.dart';
import '../../core/utils/error_reporter.dart';
import '../../core/utils/widget_image_exporter.dart';
import '../level_up/achievement_card.dart';

/// The celebration for a khatma — every page of the Mushaf read — with a card
/// to share. Resolves once the reader continues.
class KhatmaPopup {
  static Future<void> show({
    required String name,
    required int khatmas,
    required int totalPages,
  }) {
    return Get.dialog(
      _KhatmaPopupBody(name: name, khatmas: khatmas, totalPages: totalPages),
      barrierDismissible: false,
      barrierColor: Colors.black87,
    );
  }
}

class _KhatmaPopupBody extends StatefulWidget {
  const _KhatmaPopupBody({
    required this.name,
    required this.khatmas,
    required this.totalPages,
  });

  final String name;
  final int khatmas;
  final int totalPages;

  @override
  State<_KhatmaPopupBody> createState() => _KhatmaPopupBodyState();
}

class _KhatmaPopupBodyState extends State<_KhatmaPopupBody> {
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 4));
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
        filename: 'athar_khatma_${widget.khatmas}.png',
      );
      if (path != null) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], text: 'quran_khatma_share_text'.tr),
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
    final athar = context.athar;
    const onBrand = Colors.white;

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
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
                numberOfParticles: 36,
                gravity: 0.3,
                colors: [athar.gold, Colors.white, athar.sage],
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const KhatmaMedal(size: 112),
                    const SizedBox(height: AtharSpace.lg),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        'quran_khatma_title'.tr,
                        textAlign: TextAlign.center,
                        style: context.text.headlineMedium?.copyWith(color: onBrand),
                      ),
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge?.copyWith(color: onBrand.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: AtharSpace.md),
                    KhatmaPill(text: 'quran_khatma_number'.trParams({'n': '${widget.khatmas}'})),
                    const SizedBox(height: AtharSpace.md),
                    Text(
                      'quran_khatma_message'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: onBrand.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: AtharSpace.xl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _sharing ? null : _share,
                            icon: _sharing
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                  )
                                : const Icon(Icons.share_rounded, color: onBrand),
                            label: Text('share_achievement'.tr, maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: onBrand,
                              side: const BorderSide(color: Colors.white54),
                              minimumSize: const Size(64, 52),
                              padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md),
                            ),
                          ),
                        ),
                        const SizedBox(width: AtharSpace.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Get.back<void>(),
                            style: FilledButton.styleFrom(
                              backgroundColor: athar.gold,
                              foregroundColor: const Color(0xFF231A05),
                              minimumSize: const Size(64, 52),
                            ),
                            child: Text('continue_btn'.tr, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Off-screen render target for the shareable card — laid out and
            // painted, so RepaintBoundary can capture it, but out of view.
            Positioned(
              left: -2000,
              top: 0,
              child: RepaintBoundary(
                key: _cardKey,
                child: KhatmaCard(
                  name: widget.name,
                  khatmas: widget.khatmas,
                  totalPages: widget.totalPages,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shareable khatma image, in the same story-friendly portrait format as
/// the level-up [AchievementCard].
class KhatmaCard extends StatelessWidget {
  const KhatmaCard({
    super.key,
    required this.name,
    required this.khatmas,
    required this.totalPages,
  });

  final String name;
  final int khatmas;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    const onBrand = Colors.white;

    return SizedBox(
      width: 360,
      height: 640,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [athar.brand, athar.primaryDark],
              ),
            ),
          ),
          const Positioned.fill(child: CustomPaint(painter: IslamicMotifPainter())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 44,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AtharSpace.xxs),
                    Text(
                      'Athar',
                      style: context.text.labelLarge?.copyWith(
                        color: onBrand.withValues(alpha: 0.7),
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const KhatmaMedal(size: 132),
                    const SizedBox(height: AtharSpace.lg),
                    Text(
                      'quran_khatma_card_title'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.displaySmall?.copyWith(
                        color: athar.gold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        color: onBrand,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: AtharSpace.sm),
                    KhatmaPill(text: 'quran_khatma_number'.trParams({'n': '$khatmas'})),
                    const SizedBox(height: AtharSpace.sm),
                    Text(
                      'quran_khatma_pages'.trParams({'total': '$totalPages'}),
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(
                        color: onBrand.withValues(alpha: 0.75),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'quran_khatma_dua'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.titleSmall?.copyWith(
                        color: onBrand,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: AtharSpace.xs),
                    Text(
                      'أثر',
                      style: context.text.labelMedium?.copyWith(
                        color: onBrand.withValues(alpha: 0.4),
                        letterSpacing: 3,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An open Mushaf in a gold ring — the khatma's emblem.
class KhatmaMedal extends StatelessWidget {
  const KhatmaMedal({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final gold = context.athar.gold;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(AtharSpace.xxs + 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: gold, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
        ),
        child: Icon(Icons.auto_stories_rounded, size: size * 0.46, color: gold),
      ),
    );
  }
}

/// A gold-outlined pill on the khatma's dark ground.
class KhatmaPill extends StatelessWidget {
  const KhatmaPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.lg, vertical: AtharSpace.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AtharRadius.pill),
        border: Border.all(color: context.athar.gold, width: 1.4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.text.titleMedium?.copyWith(
          color: context.athar.gold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

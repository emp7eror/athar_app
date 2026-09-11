import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
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
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 4),
  );
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
          ShareParams(
            files: [XFile(path)],
            text: 'quran_khatma_share_text'.tr,
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
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryDark, AtharPalette.dark.beige],
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
                    const _Medal(size: 112),
                    const SizedBox(height: 22),
                    Text(
                      'quran_khatma_title'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Pill(
                      text: 'quran_khatma_number'.trParams({
                        'n': '${widget.khatmas}',
                      }),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'quran_khatma_message'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.6,
                      ),
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
                                      strokeWidth: 2,
                                      color: Colors.white70,
                                    ),
                                  )
                                : const Icon(
                                    Icons.share_rounded,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              'share_achievement'.tr,
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Get.back<void>(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'continue_btn'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
    return SizedBox(
      width: 360,
      height: 640,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: IslamicMotifPainter())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
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
                    const SizedBox(height: 6),
                    const Text(
                      'Athar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const _Medal(size: 132),
                    const SizedBox(height: 22),
                    Text(
                      'quran_khatma_card_title'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Pill(
                      text: 'quran_khatma_number'.trParams({'n': '$khatmas'}),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'quran_khatma_pages'.trParams({'total': '$totalPages'}),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'quran_khatma_dua'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'أثر',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 3,
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
class _Medal extends StatelessWidget {
  const _Medal({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondary, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
        ),
        child: Icon(
          Icons.auto_stories_rounded,
          size: size * 0.46,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.secondary, width: 1.4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

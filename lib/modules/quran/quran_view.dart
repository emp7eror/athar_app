import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/quran_surahs.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';

import 'page_flip/flip_settings.dart';
import 'page_flip/page_flip_controller.dart';
import 'page_flip/reading_direction.dart';
import 'page_flip/turnable_page.dart';
import 'quran_ayah_geometry.dart';
import 'quran_cover.dart';
import 'quran_page_sheet.dart';
import 'quran_controller.dart';
import 'quran_index_view.dart';

/// The ground the Mushaf script sits on, taken from the app theme so the
/// reader looks like the rest of Athar.
///
/// It follows the reader's night-mode toggle rather than the app brightness:
/// the page images are black ink, inverted to light ink at night, so the ground
/// has to contrast with the ink whatever theme the app is in.
class QuranPalette {
  /// Day reading: a warm, slightly yellow cream — gentler on the eyes than
  /// the app's near-white scaffold over a long read.
  static const paper = Color(0xFFF8EFD4);

  /// Night reading: a warm dark with a faint amber cast rather than the app's
  /// green-black, so the inverted script doesn't sit on a cold ground.
  static const nightPaper = Color(0xFF221E14);

  static Color groundFor(bool night) => night ? nightPaper : paper;
}

class QuranView extends GetView<QuranController> {
  const QuranView({super.key});

  @override
  Widget build(BuildContext context) {
    // The Mushaf is read right-to-left regardless of the app's language.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        final loading = controller.loading.value;
        final failed = controller.failed.value;
        final onCover = controller.coverVisible.value;

        return PopScope(
          // From the reader, back goes to page 0; only the cover (or a screen
          // that never got as far as the reader) leaves the Mushaf.
          canPop: onCover || loading || failed,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.showCover();
          },
          child: Scaffold(
            body: loading
                ? const Center(child: CircularProgressIndicator())
                : failed
                ? _ErrorState(onRetry: controller.load)
                : onCover
                ? const QuranCover()
                : _Reader(onBack: controller.showCover),
          ),
        );
      }),
    );
  }
}

/// A reader opened over another screen — a passage picked from the "read by
/// how you feel" results. Back returns to that screen, and page 0 underneath
/// is left exactly as it was.
class QuranPassageReaderView extends StatelessWidget {
  const QuranPassageReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _Reader(onBack: () => Get.back<void>(), browse: false),
      ),
    );
  }
}

class _Reader extends StatefulWidget {
  const _Reader({required this.onBack, this.browse = true});

  /// Where back goes — page 0 in the Mushaf, or the list a passage was opened
  /// from.
  final VoidCallback onBack;

  /// Whether the index and random-page buttons are offered. Off for a reader
  /// opened over a list: jumping somewhere from there would move page 0
  /// underneath instead of this reader.
  final bool browse;

  @override
  State<_Reader> createState() => _ReaderState();
}

class _ReaderState extends State<_Reader> {
  final controller = Get.find<QuranController>();

  /// Drives the book for the controls that never touch the paper — the surah
  /// index, the nav arrows, "random page".
  final _flip = PageFlipController();

  /// Held rather than rebuilt. [TurnablePage] takes its opening page from the
  /// settings object, so handing it a fresh one on every rebuild would send the
  /// reader back to wherever they opened the Mushaf.
  late final FlipSettings _settings;

  /// The page index the book and the controller last agreed on — what tells an
  /// external jump apart from the book reporting a turn of its own.
  late int _index;

  Worker? _jumps;

  @override
  void initState() {
    super.initState();

    _index = controller.page.value - 1;
    _settings = FlipSettings(
      startPageIndex: _index,
      flippingTime: 620,
      // Easy to turn: a short drag is enough, and a light flick carries the
      // fold the rest of the way instead of snapping back.
      swipeDistance: 24,
      inertiaVelocityThreshold: 450,
      inertiaProgressBoost: 0.35,
      maxShadowOpacity: 0.5,
      // The paper follows the finger and can be grabbed anywhere on the page.
      // Safe to open this wide because the fold now waits for real movement —
      // a thumb resting on the Mushaf starts nothing.
      cornerTriggerAreaSize: 1.0,
      // One page at a time on every screen: a facing spread would pair pages
      // the printed Mushaf does not pair.
      usePortrait: true,
    );

    // A jump that didn't come from the paper arrives as a change to `page` and
    // has to be carried to the book. A turn that *did* come from the paper has
    // already reconciled `_index`, so it stops here instead of flipping twice.
    _jumps = ever<int>(controller.page, (page) {
      if (page - 1 == _index) return;
      _index = page - 1;
      _settings.startPageIndex = _index;
      _flip.goToPage(_index);
    });
  }

  @override
  void dispose() {
    _jumps?.dispose();
    // However the reader closes — back to page 0, or back to the list it was
    // opened from — nothing is on screen any more, so nothing is being read.
    controller.stopReading();
    super.dispose();
  }

  /// The book has settled. In portrait only the first index is meaningful —
  /// there is no facing page.
  void _onPageChanged(int index, int _) {
    final target = index + 1;
    final current = controller.page.value;
    if (target == current) return;

    // A turn moves exactly one page. Anything wider did not come from the
    // paper: the book emits a page-change for its opening spread before the
    // resume page is applied, which arrived here as a jump to page 1 — enough
    // to drag the reader back to the start of the Mushaf and fetch its first
    // pages. Jumps the reader actually asked for come through `_jumps`, which
    // reconciles `_index` first and so never reaches this line.
    if ((target - current).abs() != 1) {
      _index = current - 1;
      _settings.startPageIndex = _index;
      return;
    }

    final forward = target > current;

    _index = index;
    // Kept in step so a rebuild — a rotation, or the night ground changing —
    // resumes on this page rather than the one the Mushaf was opened at.
    _settings.startPageIndex = index;

    // Going back doesn't complete the page being left: the reward belongs to
    // forward reading only.
    controller.goTo(target, countPrevious: forward);
  }

  /// A tap on the page being read: select the ayah under it and show its
  /// details. A tap on the margins just clears the selection.
  void _onAyahTap(AyahRef? ayah) {
    if (ayah == null) {
      controller.selectedAyah.value = null;
      return;
    }

    HapticFeedback.selectionClick();
    controller.selectedAyah.value = ayah;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AyahSheet(ayah: ayah, page: controller.page.value),
    ).whenComplete(() {
      if (controller.selectedAyah.value == ayah) {
        controller.selectedAyah.value = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _TopBar(
            onBack: widget.onBack,
            onIndex: widget.browse
                ? () => Get.to(() => const QuranIndexView())
                : null,
          ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Obx(() {
                      final night = controller.nightMode.value;
                      final current = controller.page.value;
                      final highlight = controller.highlight.value;
                      final selected = controller.selectedAyah.value;
                      // The book paints its own ground under and behind the
                      // pages; at night that has to be the dark paper, not
                      // the white the package would otherwise flash.
                      _settings.paperColor = QuranPalette.groundFor(night);
                      return _Sheet(
                        child: TurnablePage(
                          controller: _flip,
                          settings: _settings,
                          pageCount: controller.totalPages.value,
                          onPageChanged: _onPageChanged,
                          // Bound on the right, like the printed Mushaf.
                          readingDirection:
                              TurnableReadingDirection.rightToLeft,
                          // The Mushaf is 345x550; filling a differently
                          // proportioned box would stretch the script.
                          aspectRatio: 345 / 550,
                          autoResponseSize: false,
                          // Athar draws the paper and its shadow itself, in
                          // _Sheet, so the book adds no edges of its own.
                          pagesBoundaryIsEnabled: false,
                          builder: (context, index, constraints) =>
                              QuranPageSheet(
                                // Keyed by page so each sheet keeps its own
                                // loaded bytes instead of reloading on rebuild.
                                key: ValueKey(index + 1),
                                url: controller.imageUrlFor(index + 1),
                                ground: QuranPalette.groundFor(night),
                                nightMode: night,
                                // The page either side is the most a turn can
                                // reach, and matches what the controller warms.
                                active: (index + 1 - current).abs() <= 1,
                                highlight: highlight,
                                selected: selected,
                                // Only the page being read takes ayah taps.
                                onAyahTap: index + 1 == current
                                    ? _onAyahTap
                                    : null,
                              ),
                        ),
                      );
                    }),
                  ),
                ),
                const Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: _RewardFlash(),
                ),
              ],
            ),
          ),
          _BottomBar(
            // Back from page 1 has no earlier page to flip to, so the arrow
            // goes where back goes — page 0, or the list.
            onPrevious: () {
              if (!_flip.previousPage()) widget.onBack();
            },
            onNext: _flip.nextPage,
          ),
        ],
      ),
    );
  }
}

/// A tapped ayah: where it is, and its reference to copy or share. The page is
/// artwork, not text, so the reference is what can be passed on.
class _AyahSheet extends StatelessWidget {
  const _AyahSheet({required this.ayah, required this.page});

  final AyahRef ayah;
  final int page;

  String get _surahName => ayah.surah >= 1 && ayah.surah <= kQuranSurahs.length
      ? kQuranSurahs[ayah.surah - 1].localizedName
      : '${ayah.surah}';

  String get _reference => 'quran_ayah_reference'.trParams({
    'surah': _surahName,
    'ayah': '${ayah.ayah}',
    'ref': '${ayah.surah}:${ayah.ayah}',
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const ExcludeSemantics(
                  child: Text('📖', style: TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'quran_ayah_title'.trParams({
                        'surah': _surahName,
                        'ayah': '${ayah.ayah}',
                      }),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 38),
              child: Text(
                '${'quran_page_short'.trParams({'page': '$page'})}  ·  ${ayah.surah}:${ayah.ayah}',
                style: context.text.bodySmall?.copyWith(
                  color: context.athar.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text('quran_ayah_copy'.tr),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: _reference));
                Get.back<void>();
                Get.rawSnackbar(
                  message: 'quran_ayah_copied'.tr,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: Text('quran_ayah_share'.tr),
              onTap: () {
                Get.back<void>();
                SharePlus.instance.share(ShareParams(text: _reference));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The frame the page sits in, in the app's own background and outline so it
/// reads as part of Athar rather than a separate surface.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No shadow: the page sits flush against the header and footer, and a
    // drop shadow here bled onto both.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onIndex});

  final VoidCallback onBack;

  /// Null hides the index and random-page buttons.
  final VoidCallback? onIndex;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuranController>();
    final index = onIndex;

    return _ThemedBar(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Obx(
                () => Column(
                  children: [
                    Text(
                      'quran_surah_n'.trParams({
                        'name': controller.currentSurah.localizedName,
                      }),
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'quran_page_of'.trParams({
                        'page': '${controller.page.value}',
                        'total': '${controller.totalPages.value}',
                      }),
                      style: context.text.bodySmall?.copyWith(
                        color: context.athar.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              final marked = controller.isCurrentPageBookmarked;
              return IconButton(
                onPressed: controller.toggleBookmark,
                tooltip: marked
                    ? 'quran_bookmark_remove'.tr
                    : 'quran_bookmark_add'.tr,
                icon: Icon(
                  marked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
              );
            }),
            Obx(
              () => IconButton(
                onPressed: controller.toggleNightMode,
                tooltip: 'quran_night_mode'.tr,
                icon: Icon(
                  controller.nightMode.value
                      ? Icons.dark_mode_rounded
                      : Icons.dark_mode_outlined,
                ),
              ),
            ),
            if (index != null) ...[
              IconButton(
                onPressed: controller.randomPage,
                tooltip: 'quran_random_page'.tr,
                icon: const Icon(Icons.shuffle_rounded),
              ),
              IconButton(
                onPressed: index,
                tooltip: 'quran_index'.tr,
                icon: const Icon(Icons.menu_book_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onPrevious, required this.onNext});

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _ThemedBar(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
        child: Row(
          children: [
            // In RTL this control sits on the right, where the thumb expects
            // "back" in a Mushaf.
            _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
            const Expanded(child: _ReadingIndicator()),
            _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
          ],
        ),
      ),
    );
  }
}

/// Header and footer chrome, painted like the app's own app bar: its
/// background, and its foreground for icons, in light and dark alike.
class _ThemedBar extends StatelessWidget {
  const _ThemedBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bar = theme.appBarTheme;

    return ColoredBox(
      color: bar.backgroundColor ?? theme.scaffoldBackgroundColor,
      child: IconTheme.merge(
        data: IconThemeData(
          color: bar.foregroundColor ?? context.colors.onSurface,
        ),
        child: child,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      iconSize: 30,
      icon: Icon(icon, color: context.colors.primary),
    );
  }
}

/// A thin ring that fills over the required reading time. Deliberately quiet —
/// it's a hint, not a stopwatch.
class _ReadingIndicator extends StatelessWidget {
  const _ReadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<QuranController>();

      if (controller.isCurrentPageCompleted) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: context.athar.success,
            ),
            const SizedBox(width: 6),
            Text(
              'quran_page_done'.tr,
              style: context.text.bodySmall?.copyWith(
                color: context.athar.textMuted,
              ),
            ),
          ],
        );
      }

      // Today's reward is already banked: say so, instead of counting down
      // toward points this page can't earn.
      if (controller.dailyRewardDone) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: context.athar.success,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'quran_daily_done'.tr,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: context.athar.textMuted,
                ),
              ),
            ),
          ],
        );
      }

      final ready = controller.readingProgress >= 1;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: controller.readingProgress),
              duration: const Duration(milliseconds: 900),
              builder: (context, value, child) => CircularProgressIndicator(
                value: value,
                strokeWidth: 2,
                backgroundColor: context.athar.beige,
                valueColor: AlwaysStoppedAnimation(context.colors.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ready
                ? 'quran_turn_to_earn'.trParams({
                    'points': '${controller.pagePoints.value}',
                  })
                : 'quran_keep_reading'.tr,
            style: context.text.bodySmall?.copyWith(
              color: context.athar.textMuted,
            ),
          ),
        ],
      );
    });
  }
}

/// The "+20" that appears when a page is banked, then fades.
class _RewardFlash extends StatelessWidget {
  const _RewardFlash();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuranController>();

    return Obx(() {
      final points = controller.rewardFlash.value;

      return IgnorePointer(
        child: TweenAnimationBuilder<double>(
          // Restarting the tween on each award is what replays the animation.
          key: ValueKey('flash-$points-${controller.pagesCompleted.value}'),
          tween: Tween(begin: points > 0 ? 1 : 0, end: 0),
          duration: const Duration(milliseconds: 1800),
          curve: Curves.easeOut,
          builder: (context, t, child) {
            if (points <= 0 || t <= 0.01) return const SizedBox.shrink();
            return Opacity(
              opacity: (t * 1.6).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * -14),
                child: child,
              ),
            );
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.athar.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: context.athar.gold.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'quran_points_awarded'.trParams({'points': '$points'}),
                style: TextStyle(
                  color: context.athar.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: context.athar.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'quran_load_failed'.tr,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.athar.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text('retry'.tr)),
          ],
        ),
      ),
    );
  }
}

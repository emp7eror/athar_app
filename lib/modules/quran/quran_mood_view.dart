import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import 'quran_mood_controller.dart';
import 'quran_mood_emojis.dart';
import 'quran_mood_models.dart';
import 'quran_passage_card.dart';

/// Content never stretches wider than this on tablets and in landscape.
const double _maxContentWidth = 760;

/// "Read by how you feel": describe it in your own words, or pick what's
/// closest, then passages to reflect on.
///
/// Back walks back a step before it leaves the screen. A passage opens in a
/// reader stacked on top, so back from reading lands on the results — not on
/// page 0. Follows the app's language direction; only the Mushaf itself is
/// always right-to-left.
class QuranMoodView extends GetView<QuranMoodController> {
  const QuranMoodView({super.key});

  /// Opens the screen with its own controller, disposed when it closes.
  static void open() {
    Get.to<void>(
      () => const QuranMoodView(),
      binding: BindingsBuilder(
        () => Get.lazyPut<QuranMoodController>(() => QuranMoodController()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.step;
      final searching = controller.showingSearch;
      final section = controller.section.value;
      final category = controller.category.value;

      // Each step is handed its data rather than reading the controller, so
      // the step animating out never sees the state it was left for.
      final Widget body = switch (step) {
        0 => const _StartStep(key: ValueKey('start')),
        1 => _CategoryStep(
          key: ValueKey('section-${section!.id}'),
          section: section,
        ),
        _ =>
          searching
              ? const _SearchResultStep(key: ValueKey('search'))
              : _PickedResultStep(
                  key: ValueKey('category-${category!.id}'),
                  category: category,
                ),
      };

      return PopScope(
        canPop: step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.back();
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _Header(step: step, showCount: !searching),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Header extends GetView<QuranMoodController> {
  const _Header({required this.step, required this.showCount});

  final int step;

  /// A written feeling skips the second question, so "step 3 of 3" would
  /// mislead there.
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (!controller.back()) Get.back<void>();
                },
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  'quran_mood'.tr,
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Balances the back button so the title sits in the middle.
              const SizedBox(width: 48),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          end: (step + 1) / QuranMoodController.stepCount,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: context.athar.beige,
                          valueColor: AlwaysStoppedAnimation(
                            context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showCount) ...[
                    const SizedBox(width: 10),
                    Text(
                      'quran_mood_step'.trParams({
                        'n': '${step + 1}',
                        'total': '${QuranMoodController.stepCount}',
                      }),
                      style: context.text.bodySmall?.copyWith(
                        color: context.athar.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A scrolling step, centred and capped in width on large screens.
class _StepPage extends StatelessWidget {
  const _StepPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lays tiles out in as many columns as fit: one on a phone for long titles,
/// more on wider screens.
class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    required this.minTileWidth,
    this.maxColumns = 3,
    this.runSpacing = 10,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(
          1,
          maxColumns,
        );
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

// ── Step 1: in your own words, or pick an area ───────────────────────────────

class _StartStep extends GetView<QuranMoodController> {
  const _StartStep({super.key});

  static const _examples = [
    ('😩', 'quran_feel_example_1'),
    ('😟', 'quran_feel_example_2'),
    ('🤲', 'quran_feel_example_3'),
    ('💔', 'quran_feel_example_4'),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepPage(
      children: [
        Semantics(
          header: true,
          child: Text(
            'quran_mood_q_section'.tr,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'quran_feel_intro'.tr,
          style: context.text.bodyMedium?.copyWith(
            color: context.athar.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        const _FeelingField(),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (emoji, key) in _examples)
              ActionChip(
                avatar: ExcludeSemantics(child: Text(emoji)),
                label: Text(key.tr),
                onPressed: () => controller.useExample(key.tr),
              ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: controller.submitFeeling,
          icon: const Icon(Icons.search_rounded),
          label: Text('quran_feel_submit'.tr),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 28),
        _OrDivider(text: 'quran_mood_or_pick'.tr),
        const SizedBox(height: 14),
        Obx(() {
          if (controller.loading.value) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.failed.value) {
            return _InlineFailure(
              message: 'quran_mood_load_failed'.tr,
              onRetry: controller.load,
            );
          }
          return _ResponsiveGrid(
            minTileWidth: 150,
            maxColumns: 4,
            children: [
              for (final section in controller.sections)
                _SectionTile(
                  section: section,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.chooseSection(section);
                  },
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _FeelingField extends GetView<QuranMoodController> {
  const _FeelingField();

  @override
  Widget build(BuildContext context) {
    // Ctrl/Cmd+Enter submits from a keyboard; plain Enter starts a new line.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            controller.submitFeeling,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true):
            controller.submitFeeling,
      },
      child: Obx(
        () => TextField(
          controller: controller.input,
          focusNode: controller.focus,
          minLines: 2,
          maxLines: 6,
          maxLength: QuranMoodController.maxChars,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (_) => controller.inputError.value = null,
          decoration: InputDecoration(
            labelText: 'quran_feel_label'.tr,
            hintText: 'quran_feel_hint'.tr,
            errorText: controller.inputError.value,
            alignLabelWithHint: true,
            prefixIcon: const ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('✍️', style: TextStyle(fontSize: 20)),
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Semantics(
            header: true,
            child: Text(
              text,
              style: context.text.labelLarge?.copyWith(
                color: context.athar.textMuted,
              ),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section, required this.onTap});

  final MoodSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TileSurface(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(
                  sectionEmoji(section.id),
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                section.title.text,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 2: which feeling ────────────────────────────────────────────────────

class _CategoryStep extends GetView<QuranMoodController> {
  const _CategoryStep({super.key, required this.section});

  final MoodSection section;

  @override
  Widget build(BuildContext context) {
    return _StepPage(
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Text(
                sectionEmoji(section.id),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                section.title.text,
                style: context.text.bodySmall?.copyWith(
                  color: context.athar.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            'quran_mood_q_category'.tr,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ResponsiveGrid(
          minTileWidth: 300,
          children: [
            for (final category in section.categories)
              _CategoryTile(
                category: category,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.chooseCategory(category);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final MoodCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TileSurface(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primary.withValues(alpha: 0.08),
                ),
                child: Text(
                  categoryEmoji(category),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.title.text,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Mirrors with the text direction, so it points onward.
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: context.athar.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileSurface extends StatelessWidget {
  const _TileSurface({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.athar.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

// ── Step 3: the passages ─────────────────────────────────────────────────────

class _PickedResultStep extends GetView<QuranMoodController> {
  const _PickedResultStep({super.key, required this.category});

  final MoodCategory category;

  @override
  Widget build(BuildContext context) {
    return _StepPage(
      children: [
        _Result(
          category: category,
          urgent: false,
          guidance: controller.guidance.toList(),
          suggestible: false,
        ),
      ],
    );
  }
}

class _SearchResultStep extends GetView<QuranMoodController> {
  const _SearchResultStep({super.key});

  @override
  Widget build(BuildContext context) {
    return _StepPage(
      children: [
        Obx(() {
          final Widget content;
          final error = controller.searchError.value;
          final found = controller.found.value;

          if (controller.searching.value) {
            content = _Searching(
              key: const ValueKey('searching'),
              feeling: controller.input.text.trim(),
              onCancel: controller.cancelSearch,
            );
          } else if (error != null) {
            content = _InlineFailure(
              key: const ValueKey('error'),
              message: error,
              onRetry: controller.submitFeeling,
            );
          } else if (found != null) {
            content = _Result(
              key: ValueKey('found-${found.id}'),
              category: found,
              urgent: controller.urgent.value,
              guidance: controller.guidance.toList(),
              suggestible: true,
              footer: const _MoreStatus(),
            );
          } else {
            // Left while animating out after going back.
            content = const SizedBox.shrink();
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: content,
          );
        }),
      ],
    );
  }
}

class _Searching extends StatelessWidget {
  const _Searching({super.key, required this.feeling, required this.onCancel});

  final String feeling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (feeling.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.athar.beige,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '“$feeling”',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('quran_feel_loading'.tr)),
              TextButton(
                onPressed: onCancel,
                child: Text('quran_feel_cancel'.tr),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Looking for more passages…" under a catalog result, then how many were
/// added. A quiet note if none could be fetched — the result above stands.
class _MoreStatus extends GetView<QuranMoodController> {
  const _MoreStatus();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Widget child;
      final added = controller.moreAdded.value;

      if (controller.loadingMore.value) {
        child = Semantics(
          key: const ValueKey('loading'),
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'quran_feel_more_loading'.tr,
                    style: context.text.bodySmall?.copyWith(
                      color: context.athar.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (added > 0) {
        child = Semantics(
          key: const ValueKey('added'),
          liveRegion: true,
          child: _Note(
            emoji: '✨',
            text: 'quran_feel_more_added'.trParams({'n': '$added'}),
          ),
        );
      } else if (controller.moreFailed.value) {
        child = _Note(
          key: const ValueKey('failed'),
          text: 'quran_feel_more_failed'.tr,
        );
      } else {
        child = const SizedBox.shrink(key: ValueKey('idle'));
      }

      return AnimatedSize(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: child,
        ),
      );
    });
  }
}

class _Result extends StatelessWidget {
  const _Result({
    super.key,
    required this.category,
    required this.urgent,
    required this.guidance,
    required this.suggestible,
    this.footer,
  });

  final MoodCategory category;
  final bool urgent;
  final List<LocalizedText> guidance;

  /// A written-feeling result, which its recipient may offer for review.
  final bool suggestible;

  /// Shown right under the passages — the search's "looking for more" status.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final relevance = category.relevance.text;
    final empty = category.passages.isEmpty;
    final readerMismatch =
        category.pages.isNotEmpty && !QuranPassageCard.readerMatches();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                categoryEmoji(category),
                style: const TextStyle(fontSize: 34),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  category.title.text,
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (urgent)
          _UrgentGuidance(text: relevance)
        else if (!empty)
          Text(
            relevance,
            style: context.text.bodyMedium?.copyWith(
              color: context.athar.textMuted,
              height: 1.7,
            ),
          ),
        if (empty)
          // The explanation, never a stand-in recommendation.
          _EmptyResult(explanation: urgent ? null : relevance)
        else ...[
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              '📖  ${'quran_mood_results'.tr}',
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ResponsiveGrid(
            minTileWidth: 320,
            maxColumns: 2,
            runSpacing: 0,
            children: [
              for (final passage in category.passages)
                QuranPassageCard(passage: passage),
            ],
          ),
          ?footer,
          if (readerMismatch)
            _Note(emoji: 'ℹ️', text: 'quran_feel_reader_mismatch'.tr),
        ],
        const SizedBox(height: 6),
        _Note(emoji: '💡', text: 'quran_feel_reflection_note'.tr),
        for (final note in guidance) _Note(text: note.text),
        if (category.sourceUrls.isNotEmpty) _Sources(urls: category.sourceUrls),
        if (suggestible) const _Suggest(),
      ],
    );
  }
}

/// The server leads relevance with urgent guidance; it is shown first and set
/// apart, never buried under the passages.
class _UrgentGuidance extends StatelessWidget {
  const _UrgentGuidance({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final onColor = context.colors.onErrorContainer;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety_rounded, color: onColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'quran_feel_safety_label'.tr,
                    style: TextStyle(
                      color: onColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(text, style: TextStyle(color: onColor, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.explanation});

  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final text = explanation;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.athar.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        children: [
          const ExcludeSemantics(
            child: Text('🔍', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Text(
            'quran_feel_empty_title'.tr,
            textAlign: TextAlign.center,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (text != null && text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.athar.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.text, this.emoji});

  final String text;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final mark = emoji;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mark != null) ...[
            ExcludeSemantics(child: Text(mark)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                color: context.athar.textMuted,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Links are opened only as http(s), outside the app, and shown as plain text.
class _Sources extends StatelessWidget {
  const _Sources({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final links = [
      for (final url in urls)
        if (Uri.tryParse(url) case final uri?
            when (uri.scheme == 'https' || uri.scheme == 'http') &&
                uri.host.isNotEmpty)
          uri,
    ];
    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              '🔗  ${'quran_feel_sources'.tr}',
              style: context.text.labelLarge?.copyWith(
                color: context.athar.textMuted,
              ),
            ),
          ),
          for (final uri in links)
            TextButton.icon(
              onPressed: () =>
                  launchUrl(uri, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                '${uri.host}${uri.path}',
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
              ),
            ),
        ],
      ),
    );
  }
}

class _Suggest extends GetView<QuranMoodController> {
  const _Suggest();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.canSuggest.value) return const SizedBox.shrink();

      final state = controller.suggestState.value;
      final message = controller.suggestMessage.value;

      return Container(
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.athar.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quran_feel_suggest_note'.tr,
              style: context.text.bodySmall?.copyWith(
                color: context.athar.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            switch (state) {
              FeelingSuggestState.idle => OutlinedButton.icon(
                onPressed: controller.suggest,
                icon: const ExcludeSemantics(child: Text('📨')),
                label: Text('quran_feel_suggest'.tr),
              ),
              FeelingSuggestState.sending => const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              FeelingSuggestState.sent => Semantics(
                liveRegion: true,
                child: Text('✅  ${message ?? 'quran_feel_suggest_sent'.tr}'),
              ),
              FeelingSuggestState.failed => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(message ?? 'quran_feel_suggest_failed'.tr),
                  ),
                  TextButton(
                    onPressed: controller.suggest,
                    child: Text('retry'.tr),
                  ),
                ],
              ),
              FeelingSuggestState.closed => Semantics(
                liveRegion: true,
                child: Text(message ?? 'quran_feel_suggest_failed'.tr),
              ),
            },
          ],
        ),
      );
    });
  }
}

class _InlineFailure extends StatelessWidget {
  const _InlineFailure({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.athar.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        children: [
          const ExcludeSemantics(
            child: Text('📡', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text('retry'.tr)),
        ],
      ),
    );
  }
}

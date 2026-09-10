import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import 'quran_controller.dart';
import 'quran_mood_controller.dart';
import 'quran_mood_models.dart';
import 'quran_view.dart';

/// "Read by how you feel": two questions, then passages to reflect on.
///
/// Back walks back through the questions before it leaves the screen. A passage
/// opens in a reader stacked on top of the results, so back from reading lands
/// here — not on page 0.
class QuranMoodView extends GetView<QuranMoodController> {
  const QuranMoodView({super.key});

  /// Opens the questionnaire with its own controller, disposed when it closes.
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        final loading = controller.loading.value;
        final failed = controller.failed.value;
        final step = controller.step;
        final ready = !loading && !failed;

        final Widget body;
        if (loading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (failed) {
          body = _Failed(onRetry: controller.load);
        } else {
          body = AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            // Each step is handed its data, rather than reading the controller,
            // so the step animating out never sees the state it was left for.
            child: switch (step) {
              0 => _SectionQuestion(
                key: const ValueKey('sections'),
                sections: controller.sections.toList(),
              ),
              1 => _CategoryQuestion(
                key: ValueKey('section-${controller.section.value!.id}'),
                section: controller.section.value!,
              ),
              _ => _Results(
                key: ValueKey('category-${controller.category.value!.id}'),
                category: controller.category.value!,
                guidance: controller.guidance.toList(),
              ),
            },
          );
        }

        return PopScope(
          // Back from a later step returns to the question before it.
          canPop: !ready || step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.back();
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _Header(step: ready ? step : null),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step});

  /// The questionnaire step, or null while it is still loading.
  final int? step;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuranMoodController>();
    final current = step;

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
          if (current != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (current + 1) / QuranMoodController.stepCount,
                        minHeight: 4,
                        backgroundColor: context.athar.beige,
                        valueColor: AlwaysStoppedAnimation(
                          context.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'quran_mood_step'.trParams({
                      'n': '${current + 1}',
                      'total': '${QuranMoodController.stepCount}',
                    }),
                    style: context.text.bodySmall?.copyWith(
                      color: context.athar.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionQuestion extends StatelessWidget {
  const _SectionQuestion({super.key, required this.sections});

  final List<MoodSection> sections;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuranMoodController>();

    return _Question(
      prompt: 'quran_mood_q_section'.tr,
      children: [
        for (final section in sections)
          _Choice(
            label: section.title.text,
            onTap: () => controller.chooseSection(section),
          ),
      ],
    );
  }
}

class _CategoryQuestion extends StatelessWidget {
  const _CategoryQuestion({super.key, required this.section});

  final MoodSection section;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuranMoodController>();

    return _Question(
      prompt: 'quran_mood_q_category'.tr,
      answer: section.title.text,
      children: [
        for (final category in section.categories)
          _Choice(
            label: category.title.text,
            onTap: () => controller.chooseCategory(category),
          ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.prompt,
    required this.children,
    this.answer,
  });

  final String prompt;

  /// The earlier answer this question narrows down, shown above it.
  final String? answer;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final earlier = answer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (earlier != null) ...[
          Text(
            earlier,
            style: context.text.bodySmall?.copyWith(
              color: context.athar.textMuted,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          prompt,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({super.key, required this.category, required this.guidance});

  final MoodCategory category;
  final List<LocalizedText> guidance;

  static String _ayahs(MoodPassage p) {
    if (p.isCompleteSurah) return 'quran_mood_whole_surah'.tr;
    if (p.ayahStart == p.ayahEnd) {
      return 'quran_mood_ayah'.trParams({'n': '${p.ayahStart}'});
    }
    return 'quran_mood_ayahs'.trParams({
      'from': '${p.ayahStart}',
      'to': '${p.ayahEnd}',
    });
  }

  static String _pages(MoodPassage p) {
    if (p.pages.length == 1) {
      return 'quran_page_short'.trParams({'page': '${p.pages.first}'});
    }
    return 'quran_mood_pages'.trParams({
      'from': '${p.pages.first}',
      'to': '${p.pages.last}',
    });
  }

  /// Opens the passage over these results; back from the reader returns here.
  void _read(MoodPassage passage) {
    Get.find<QuranController>().readAt(passage.firstPage);
    Get.to<void>(() => const QuranPassageReaderView());
  }

  @override
  Widget build(BuildContext context) {
    final relevance = category.relevance.text;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          category.title.text,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (relevance.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            relevance,
            style: context.text.bodyMedium?.copyWith(
              color: context.athar.textMuted,
              height: 1.6,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'quran_mood_results'.tr,
          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final passage in category.passages)
          _Choice(
            leading: _SurahBadge(number: passage.surahNumber),
            label: 'quran_surah_n'.trParams({'name': passage.surahName.text}),
            subtitle: '${_ayahs(passage)}  ·  ${_pages(passage)}',
            onTap: () => _read(passage),
          ),
        for (final note in guidance)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              note.text,
              style: context.text.bodySmall?.copyWith(
                color: context.athar.textMuted,
                height: 1.6,
              ),
            ),
          ),
      ],
    );
  }
}

/// One answer, or one passage — a card that leads onward.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    final lead = leading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.athar.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (lead != null) ...[lead, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      if (sub != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          sub,
                          style: context.text.bodySmall?.copyWith(
                            color: context.athar.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Mirrors with the text direction, so it points onward in RTL.
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: context.athar.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahBadge extends StatelessWidget {
  const _SurahBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.primary.withValues(alpha: 0.12),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: context.colors.primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});

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
              'quran_mood_load_failed'.tr,
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

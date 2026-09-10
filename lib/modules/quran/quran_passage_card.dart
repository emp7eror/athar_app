import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import 'quran_ayah_geometry.dart';
import 'quran_controller.dart';
import 'quran_mood_models.dart';
import 'quran_view.dart';

/// One suggested passage: surah, ayah range and pages.
///
/// Tapping opens its first page in a reader stacked over the current screen,
/// so back returns here. That is offered only when the pages are verified and
/// the reader uses the same pagination; otherwise the reference stands on its
/// own, and a passage without pages says they are unavailable.
class QuranPassageCard extends StatelessWidget {
  const QuranPassageCard({super.key, required this.passage});

  final MoodPassage passage;

  /// Whether the Mushaf reader shows the edition verified pages refer to.
  static bool readerMatches() =>
      Get.isRegistered<QuranController>() &&
      Get.find<QuranController>().pagesMatchReader;

  static String ayahs(MoodPassage p) {
    if (p.isCompleteSurah) return 'quran_mood_whole_surah'.tr;
    if (p.ayahStart == p.ayahEnd) {
      return 'quran_mood_ayah'.trParams({'n': '${p.ayahStart}'});
    }
    return 'quran_mood_ayahs'.trParams({
      'from': '${p.ayahStart}',
      'to': '${p.ayahEnd}',
    });
  }

  static String pages(MoodPassage p) {
    if (p.pages.isEmpty) return 'quran_feel_pages_unavailable'.tr;
    if (p.pages.length == 1) {
      return 'quran_page_short'.trParams({'page': '${p.pages.first}'});
    }
    return 'quran_mood_pages'.trParams({
      'from': '${p.pages.first}',
      'to': '${p.pages.last}',
    });
  }

  /// Opens the first page with the passage's ayahs set apart.
  void _read() {
    Get.find<QuranController>().readAt(
      passage.pages.first,
      highlight: AyahRange(
        passage.surahNumber,
        passage.ayahStart,
        passage.ayahEnd,
      ),
    );
    Get.to<void>(() => const QuranPassageReaderView());
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = passage.pages.isNotEmpty && readerMatches();

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
          onTap: canOpen ? _read : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: _SurahBadge(number: passage.surahNumber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quran_surah_n'.trParams({
                          'name': passage.surahName.text,
                        }),
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${ayahs(passage)}  ·  ${pages(passage)}',
                        style: context.text.bodySmall?.copyWith(
                          color: context.athar.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canOpen) ...[
                  const SizedBox(width: 8),
                  // Mirrors with the text direction, so it points onward.
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: context.athar.textMuted,
                    semanticLabel: 'quran_feel_open_page'.tr,
                  ),
                ],
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

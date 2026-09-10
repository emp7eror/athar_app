import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/quran_surahs.dart';
import '../../core/theme/app_theme.dart';
import 'quran_controller.dart';
import 'quran_index_view.dart';
import 'quran_mood_view.dart';

/// "Page 0" — what the Mushaf opens on.
///
/// Five ways in: the index, reading by how you feel, a random page, the saved
/// bookmark, and the page last read. Nothing is opened and no reading clock runs until one is chosen,
/// and the reader returns here when it goes back from page 1.
class QuranCover extends GetView<QuranController> {
  const QuranCover({super.key});

  /// "Surah Al-Baqarah · p. 12" for a page.
  static String _where(int page) =>
      '${'quran_surah_n'.trParams({'name': surahForPage(page).localizedName})}'
      '  ·  ${'quran_page_short'.trParams({'page': '$page'})}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: Get.back<void>,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    'quran_title'.tr,
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
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const _Emblem(),
                const SizedBox(height: 28),
                _Option(
                  icon: Icons.menu_book_rounded,
                  title: 'quran_index'.tr,
                  subtitle: 'quran_cover_index_sub'.tr,
                  onTap: () => Get.to<void>(() => const QuranIndexView()),
                ),
                _Option(
                  icon: Icons.volunteer_activism_rounded,
                  title: 'quran_mood'.tr,
                  subtitle: 'quran_mood_sub'.tr,
                  onTap: QuranMoodView.open,
                ),
                _Option(
                  icon: Icons.shuffle_rounded,
                  title: 'quran_random_page'.tr,
                  subtitle: 'quran_cover_random_sub'.tr,
                  onTap: controller.randomPage,
                ),
                Obx(() {
                  final bookmark = controller.bookmarkPage.value;
                  return _Option(
                    icon: Icons.bookmark_rounded,
                    title: 'quran_bookmark'.tr,
                    subtitle: bookmark == null
                        ? 'quran_no_bookmark'.tr
                        : _where(bookmark),
                    onTap: bookmark == null
                        ? null
                        : () => controller.openAt(bookmark),
                  );
                }),
                Obx(() {
                  final last = controller.lastReadPage.value;
                  return _Option(
                    icon: Icons.history_rounded,
                    title: 'quran_last_read'.tr,
                    subtitle: _where(last),
                    onTap: () => controller.openAt(last),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: context.athar.heroGradient,
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'quran_cover_title'.tr,
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'quran_home_card_sub'.tr,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: context.athar.textMuted,
          ),
        ),
      ],
    );
  }
}

/// One way into the Mushaf. Dimmed and inert when [onTap] is null — the
/// bookmark before one has been set.
class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.athar.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.5 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, color: context.colors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: context.text.bodySmall?.copyWith(
                            color: context.athar.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
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
      ),
    );
  }
}

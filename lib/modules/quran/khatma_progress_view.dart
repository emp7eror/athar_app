import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/quran_surahs.dart';
import '../../core/theme/app_theme.dart';
import 'quran_controller.dart';
import 'quran_cover.dart';

/// Opens [page] in the reader and closes this screen.
void _open(int page) {
  Get.find<QuranController>().openAt(page);
  Get.back<void>();
}

/// How far the current khatma has come: overall, per surah, per juz and page
/// by page — with a way straight to a page not read yet.
class KhatmaProgressView extends GetView<QuranController> {
  const KhatmaProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('quran_khatma_map'.tr),
          bottom: TabBar(
            tabs: [
              Tab(text: 'quran_tab_surah'.tr),
              Tab(text: 'quran_tab_juz'.tr),
              Tab(text: 'quran_tab_page'.tr),
            ],
          ),
        ),
        body: const Column(
          children: [
            _Summary(),
            Expanded(
              child: TabBarView(
                children: [_SurahProgress(), _JuzProgress(), _PageGrid()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends GetView<QuranController> {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.totalPages.value;
      final read = controller.khatmaReadPages.length.clamp(0, total);
      final percent = total > 0 ? (read * 100 / total).floor() : 0;
      final next = controller.nextUnreadPage();

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: context.athar.heroGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'quran_khatma_pages_read'.trParams({'read': '$read', 'total': '$total'}),
                    style: context.text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$percent%',
                  style: context.text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? read / total : 0,
                minHeight: 7,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(context.athar.gold),
              ),
            ),
            const SizedBox(height: 14),
            if (next == null)
              Text(
                'quran_khatma_all_read'.tr,
                style: context.text.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              )
            else
              FilledButton.icon(
                onPressed: () => _open(next),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: context.colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                ),
                icon: const Icon(Icons.flag_rounded, size: 18),
                label: Text(
                  '${'quran_next_unread_go'.tr}  ·  ${QuranCover.where(next)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _SurahProgress extends GetView<QuranController> {
  const _SurahProgress();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: kQuranSurahs.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: context.athar.beige, indent: 68),
      itemBuilder: (context, i) {
        final s = kQuranSurahs[i];
        return Obx(() {
          final (first, last) = controller.surahPages(s.number);
          final p = controller.khatmaProgress(first, last);
          return _ProgressTile(
            ring: KhatmaRing(label: '${s.number}', read: p.read, total: p.total),
            title: 'quran_surah_n'.trParams({'name': s.localizedName}),
            read: p.read,
            total: p.total,
            onTap: () => _open(controller.firstUnread(first, last) ?? first),
          );
        });
      },
    );
  }
}

class _JuzProgress extends GetView<QuranController> {
  const _JuzProgress();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: kJuzStartPages.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: context.athar.beige, indent: 68),
      itemBuilder: (context, i) {
        final juz = i + 1;
        return Obx(() {
          final (first, last) = controller.juzPages(juz);
          final p = controller.khatmaProgress(first, last);
          return _ProgressTile(
            ring: KhatmaRing(label: '$juz', read: p.read, total: p.total),
            title: 'quran_juz_n'.trParams({'n': '$juz'}),
            read: p.read,
            total: p.total,
            onTap: () => _open(controller.firstUnread(first, last) ?? first),
          );
        });
      },
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.ring,
    required this.title,
    required this.read,
    required this.total,
    required this.onTap,
  });

  final Widget ring;
  final String title;
  final int read;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final done = total > 0 && read >= total;

    return ListTile(
      onTap: onTap,
      leading: ring,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        'quran_khatma_pages_read'.trParams({'read': '$read', 'total': '$total'}),
        style: TextStyle(color: athar.textMuted, fontSize: 11.5),
      ),
      trailing: done
          ? Text(
              'quran_khatma_done'.tr,
              style: TextStyle(color: athar.success, fontWeight: FontWeight.w700, fontSize: 12),
            )
          : Text(
              read == 0 ? 'quran_khatma_start'.tr : 'quran_khatma_resume'.tr,
              style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700, fontSize: 12),
            ),
    );
  }
}

/// Every page of the Mushaf as a square: filled once read in this khatma,
/// outlined in gold for the page last read.
class _PageGrid extends GetView<QuranController> {
  const _PageGrid();

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final colors = context.colors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _Legend(color: colors.primary, label: 'quran_khatma_legend_read'.tr),
              const SizedBox(width: 16),
              _Legend(color: athar.card, border: colors.outline, label: 'quran_khatma_legend_unread'.tr),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 52,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: controller.totalPages.value,
            itemBuilder: (context, i) {
              final page = i + 1;
              return Obx(() {
                final read = controller.isReadInKhatma(page);
                final last = controller.lastReadPage.value == page;
                return Material(
                  color: read ? colors.primary : athar.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: last ? athar.gold : (read ? Colors.transparent : colors.outline),
                      width: last ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _open(page),
                    child: Center(
                      child: Text(
                        '$page',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: read ? colors.onPrimary : athar.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.border});

  final Color color;
  final Color? border;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border == null ? null : Border.all(color: border!),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.athar.textMuted, fontSize: 12)),
      ],
    );
  }
}

/// A small ring filling with a surah's or juz's pages read in this khatma,
/// with its number inside — a check once it is complete.
class KhatmaRing extends StatelessWidget {
  const KhatmaRing({
    super.key,
    required this.label,
    required this.read,
    required this.total,
    this.size = 38,
  });

  final String label;
  final int read;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final primary = context.colors.primary;
    final done = total > 0 && read >= total;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: total > 0 ? read / total : 0,
              strokeWidth: 3,
              backgroundColor: athar.beige,
              valueColor: AlwaysStoppedAnimation(done ? athar.success : primary),
            ),
          ),
          if (done)
            Icon(Icons.check_rounded, size: 18, color: athar.success)
          else
            Text(
              label,
              style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

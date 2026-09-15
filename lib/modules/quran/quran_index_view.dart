import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/quran_surahs.dart';
import '../../core/ui/athar_ui.dart';
import 'khatma_progress_view.dart';
import 'quran_controller.dart';

/// Surah / Juz / page index. Picking anything closes the index and lands the
/// reader on that page with a normal flip.
class QuranIndexView extends GetView<QuranController> {
  const QuranIndexView({super.key});

  @override
  Widget build(BuildContext context) {
    // Follows the app's language, like the rest of the app's menus.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AtharAppBar(
          title: 'quran_index'.tr,
          actions: [
            // Replaces the index, so opening a page from there still lands in
            // the reader rather than back here.
            AtharIconButton(
              icon: Icons.insights_rounded,
              tooltip: 'quran_khatma_map'.tr,
              onPressed: () => Get.off<void>(() => const KhatmaProgressView()),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'quran_tab_surah'.tr),
              Tab(text: 'quran_tab_juz'.tr),
              Tab(text: 'quran_tab_page'.tr),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_SurahList(), _JuzList(), _PagePicker()],
        ),
      ),
    );
  }
}

void _jumpTo(int page) {
  // openAt works from the cover as well as from the reader.
  Get.find<QuranController>().openAt(page);
  Get.back<void>();
}

class _SurahList extends StatelessWidget {
  const _SurahList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AtharSpace.xs),
      itemCount: kQuranSurahs.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final s = kQuranSurahs[i];
        return ListTile(
          onTap: () => _jumpTo(s.page),
          // Fills with the surah's pages read in this khatma.
          leading: Obx(() {
            final c = Get.find<QuranController>();
            final (first, last) = c.surahPages(s.number);
            final p = c.khatmaProgress(first, last);
            return KhatmaRing(label: '${s.number}', read: p.read, total: p.total);
          }),
          title: Text('quran_surah_n'.trParams({'name': s.localizedName})),
          subtitle: Text(
            '${s.otherName}  ·  ${s.isMeccan ? 'quran_meccan'.tr : 'quran_medinan'.tr}  ·  ${s.ayahs} ${'quran_ayahs'.tr}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            'quran_page_short'.trParams({'page': '${s.page}'}),
            style: context.type.caption,
          ),
        );
      },
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AtharSpace.xs),
      itemCount: kJuzStartPages.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final page = kJuzStartPages[i];
        return ListTile(
          onTap: () => _jumpTo(page),
          leading: Obx(() {
            final c = Get.find<QuranController>();
            final (first, last) = c.juzPages(i + 1);
            final p = c.khatmaProgress(first, last);
            return KhatmaRing(label: '${i + 1}', read: p.read, total: p.total);
          }),
          title: Text('quran_juz_n'.trParams({'n': '${i + 1}'})),
          subtitle: Text(
            'quran_surah_n'.trParams({'name': surahForPage(page).localizedName}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            'quran_page_short'.trParams({'page': '$page'}),
            style: context.type.caption,
          ),
        );
      },
    );
  }
}

class _PagePicker extends StatefulWidget {
  const _PagePicker();

  @override
  State<_PagePicker> createState() => _PagePickerState();
}

class _PagePickerState extends State<_PagePicker> {
  final _field = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final total = Get.find<QuranController>().totalPages.value;
    final value = int.tryParse(_field.text.trim());

    if (value == null || value < 1 || value > total) {
      setState(() => _error = 'quran_page_range'.trParams({'total': '$total'}));
      return;
    }

    _jumpTo(value);
  }

  @override
  Widget build(BuildContext context) {
    final total = Get.find<QuranController>().totalPages.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.lg, AtharSpace.screen, AtharSpace.lg),
      children: [
        TextField(
          controller: _field,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: context.text.headlineSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(hintText: '1 – $total', errorText: _error),
        ),
        const SizedBox(height: AtharSpace.md),
        AtharButton(label: 'quran_go_to_page'.tr, expand: true, onPressed: _submit),
        const SizedBox(height: AtharSpace.lg),
        Center(
          child: AtharButton(
            label: 'quran_random_page'.tr,
            icon: Icons.shuffle_rounded,
            variant: AtharButtonVariant.ghost,
            onPressed: () {
              Get.find<QuranController>().randomPage();
              Get.back<void>();
            },
          ),
        ),
      ],
    );
  }
}

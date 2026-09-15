import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/quran_surahs.dart';
import '../../core/theme/app_theme.dart';
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
        appBar: AppBar(
          title: Text('quran_index'.tr),
          actions: [
            // Replaces the index, so opening a page from there still lands in
            // the reader rather than back here.
            IconButton(
              tooltip: 'quran_khatma_map'.tr,
              icon: const Icon(Icons.insights_rounded),
              onPressed: () => Get.off<void>(() => const KhatmaProgressView()),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.athar.textMuted,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: kQuranSurahs.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: context.athar.beige, indent: 68),
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
          title: Text(
            'quran_surah_n'.trParams({'name': s.localizedName}),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${s.otherName}  ·  ${s.isMeccan ? 'quran_meccan'.tr : 'quran_medinan'.tr}  ·  ${s.ayahs} ${'quran_ayahs'.tr}',
            style: TextStyle(color: context.athar.textMuted, fontSize: 11.5),
          ),
          trailing: Text(
            'quran_page_short'.trParams({'page': '${s.page}'}),
            style: TextStyle(color: context.athar.textMuted, fontSize: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: kJuzStartPages.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: context.athar.beige, indent: 68),
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
          title: Text(
            'quran_juz_n'.trParams({'n': '${i + 1}'}),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'quran_surah_n'.trParams({
              'name': surahForPage(page).localizedName,
            }),
            style: TextStyle(color: context.athar.textMuted, fontSize: 11.5),
          ),
          trailing: Text(
            'quran_page_short'.trParams({'page': '$page'}),
            style: TextStyle(color: context.athar.textMuted, fontSize: 12),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        TextField(
          controller: _field,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: '1 – $total',
            hintStyle: TextStyle(
              color: context.athar.textMuted,
              fontWeight: FontWeight.w400,
            ),
            errorText: _error,
            filled: true,
            fillColor: context.athar.beige,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.athar.beige),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text('quran_go_to_page'.tr),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Get.find<QuranController>().randomPage();
              Get.back<void>();
            },
            icon: const Icon(Icons.shuffle_rounded, size: 18),
            label: Text('quran_random_page'.tr),
          ),
        ),
      ],
    );
  }
}

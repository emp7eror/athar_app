import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import 'tafsir_models.dart';
import 'tafsir_service.dart';

/// Arabic-script text (Arabic, Urdu, Persian, Pashto, Uyghur, Kurdish…) reads
/// right to left whatever language the app is in.
TextDirection _directionOf(String text) =>
    RegExp(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]').hasMatch(
      text.length > 200 ? text.substring(0, 200) : text,
    )
        ? TextDirection.rtl
        : TextDirection.ltr;

/// The tafsir of one ayah in the chosen edition, with a button to change the
/// edition. Lives in the ayah sheet.
class AyahTafsirSection extends StatefulWidget {
  const AyahTafsirSection({super.key, required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  State<AyahTafsirSection> createState() => _AyahTafsirSectionState();
}

class _AyahTafsirSectionState extends State<AyahTafsirSection> {
  final _service = TafsirService.instance;

  /// Collapsed at first: nothing is fetched until the reader opens it.
  bool _expanded = false;
  Future<AyahTafsir?>? _future;
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _worker = ever<String>(_service.selectedSlug, (_) {
      if (mounted && _expanded) setState(_load);
    });
  }

  void _load() {
    _future = _service.ayah(_service.selectedSlug.value, widget.surah, widget.ayah);
    // The edition's name comes from the list, loaded alongside the text.
    _service.editions().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object _) {});
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded && _future == null) _load();
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;
    final edition = _service.editionFor(_service.selectedSlug.value);

    // Its own Material, so the header's ink shows on the beige instead of under it.
    return Material(
      color: athar.beige,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
      padding: EdgeInsetsDirectional.fromSTEB(12, 4, 4, _expanded ? 16 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 8),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 20, color: athar.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edition?.name ?? 'tafsir_title'.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (edition != null)
                          Text(
                            [
                              TafsirLanguages.label(edition.language),
                              if (edition.author.isNotEmpty) edition.author,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(color: athar.textMuted),
                          ),
                      ],
                    ),
                  ),
                  if (_expanded)
                    TextButton.icon(
                      onPressed: () => showTafsirPicker(context),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text('tafsir_change'.tr),
                    ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: athar.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
          const SizedBox(height: 10),
          FutureBuilder<AyahTafsir?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (snap.hasError) {
                return _Notice(
                  icon: Icons.wifi_off_rounded,
                  text: 'tafsir_load_failed'.tr,
                  action: TextButton(
                    onPressed: () => setState(_load),
                    child: Text('retry'.tr),
                  ),
                );
              }

              final tafsir = snap.data;
              if (tafsir == null) {
                return _Notice(
                  icon: Icons.info_outline_rounded,
                  text: 'tafsir_none'.tr,
                  action: TextButton(
                    onPressed: () => showTafsirPicker(context),
                    child: Text('tafsir_choose_other'.tr),
                  ),
                );
              }

              final direction = _directionOf(tafsir.text);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tafsir.sharedWithEarlierAyah) ...[
                    Row(
                      children: [
                        Icon(Icons.link_rounded, size: 16, color: athar.gold),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'tafsir_shared'.trParams({
                              'from': '${tafsir.sourceAyah}',
                              'to': '${tafsir.ayah}',
                            }),
                            style: context.text.bodySmall?.copyWith(
                              color: athar.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  SelectableText(
                    tafsir.text,
                    textDirection: direction,
                    textAlign: direction == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                    style: context.text.bodyMedium?.copyWith(height: 1.9, fontSize: 15),
                  ),
                ],
              );
            },
          ),
          ],
        ],
      ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final muted = context.athar.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: muted, size: 26),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: muted)),
          ?action,
        ],
      ),
    );
  }
}

/// Lets the reader pick the tafsir shown for every ayah: languages first (the
/// app's language, then the edition's, then the rest), then that language's
/// editions. The choice is remembered.
Future<void> showTafsirPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _TafsirPicker(),
  );
}

class _TafsirPicker extends StatefulWidget {
  const _TafsirPicker();

  @override
  State<_TafsirPicker> createState() => _TafsirPickerState();
}

class _TafsirPickerState extends State<_TafsirPicker> {
  final _service = TafsirService.instance;
  late Future<List<TafsirEdition>> _future = _service.editions();
  String? _language;

  List<String> _languagesOf(List<TafsirEdition> editions) {
    final counts = <String, int>{};
    for (final e in editions) {
      counts[e.language] = (counts[e.language] ?? 0) + 1;
    }
    final app = Get.locale?.languageCode;
    final current = _service.editionFor(_service.selectedSlug.value)?.language;
    final first = <String>{?app, ?current}.where(counts.containsKey).toList();
    final rest = counts.keys.where((l) => !first.contains(l)).toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [...first, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => FutureBuilder<List<TafsirEdition>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || (snap.data ?? const []).isEmpty) {
            return _Notice(
              icon: Icons.wifi_off_rounded,
              text: 'tafsir_editions_failed'.tr,
              action: TextButton(
                onPressed: () => setState(() => _future = _service.editions()),
                child: Text('retry'.tr),
              ),
            );
          }

          final editions = snap.data!;
          final languages = _languagesOf(editions);
          final language = _language ?? languages.first;
          final shown = editions.where((e) => e.language == language).toList();

          return Obx(() {
            // The resolved edition, so the default is ticked before any choice.
            final selected = _service.editionFor(_service.selectedSlug.value)?.slug;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'tafsir_choose'.tr,
                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: languages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final l = languages[i];
                      return ChoiceChip(
                        label: Text(TafsirLanguages.label(l)),
                        selected: l == language,
                        onSelected: (_) => setState(() => _language = l),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final e = shown[i];
                      final isSelected = e.slug == selected;
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        selected: isSelected,
                        selectedTileColor: athar.gold.withValues(alpha: 0.12),
                        leading: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.menu_book_outlined,
                          color: isSelected ? athar.gold : athar.textMuted,
                        ),
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: e.author.isEmpty ? null : Text(e.author),
                        onTap: () {
                          _service.select(e.slug);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }
}

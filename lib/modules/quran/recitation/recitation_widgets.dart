import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/quran_surahs.dart';
import '../../../core/theme/app_theme.dart';
import '../quran_ayah_geometry.dart';
import 'recitation_models.dart';
import 'recitation_service.dart';

String _surahName(int surah) => surah >= 1 && surah <= kQuranSurahs.length
    ? kQuranSurahs[surah - 1].localizedName
    : '$surah';

String _clock(Duration d) {
  final s = d.inSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

/// "Listen from this ayah", in the ayah sheet, with the reciter it will use.
class AyahListenTile extends StatefulWidget {
  const AyahListenTile({super.key, required this.ayah});

  final AyahRef ayah;

  @override
  State<AyahListenTile> createState() => _AyahListenTileState();
}

class _AyahListenTileState extends State<AyahListenTile> {
  final _service = RecitationService.instance;

  @override
  void initState() {
    super.initState();
    // The reciter's name comes from the list; load it so the tile can show it.
    _service.reciters().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;

    // Its own Material, so the tile's ink shows on the beige instead of under it.
    return Material(
      color: athar.beige,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Obx(() {
        final voice = _service.reciterFor(_service.selectedSlug.value);
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 4),
          leading: CircleAvatar(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
            child: const Icon(Icons.play_arrow_rounded),
          ),
          title: Text(
            'recitation_listen_from'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: voice == null ? null : Text(voice.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: TextButton(
            onPressed: () => showReciterPicker(context),
            child: Text('recitation_change'.tr),
          ),
          onTap: () {
            Get.back<void>();
            _service.playFrom(widget.ayah);
          },
        );
      }),
    );
  }
}

/// The player under the page while a recitation is on: which ayah, the
/// reciter, a seek bar, and previous / play-pause / next / stop.
class RecitationPlayerBar extends StatelessWidget {
  const RecitationPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RecitationService.instance;
    final athar = context.athar;

    return Obx(() {
      final ayah = service.current.value;
      if (ayah == null) return const SizedBox.shrink();

      final playing = service.playing.value;
      final loading = service.loading.value;
      final failed = service.failed.value;
      final total = service.duration.value;
      final at = service.position.value;
      final voice = service.reciterFor(service.selectedSlug.value);

      // "Next" points the way the text reads: left in Arabic, right in English.
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final max = total.inMilliseconds.toDouble();
      final value = at.inMilliseconds.clamp(0, total.inMilliseconds).toDouble();

      return Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        decoration: BoxDecoration(
          color: athar.card,
          border: Border(top: BorderSide(color: context.colors.outline)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq_rounded, color: athar.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'recitation_now'.trParams({
                          'surah': _surahName(ayah.surah),
                          'ayah': '${ayah.ayah}',
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      InkWell(
                        onTap: () => showReciterPicker(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                failed ? 'recitation_load_failed'.tr : (voice?.name ?? 'recitation_reciter'.tr),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall?.copyWith(
                                  color: failed ? context.colors.error : athar.textMuted,
                                ),
                              ),
                            ),
                            if (!failed) Icon(Icons.expand_more_rounded, size: 16, color: athar.textMuted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: service.stop,
                  tooltip: 'recitation_stop'.tr,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(_clock(at), style: context.text.labelSmall?.copyWith(color: athar.textMuted)),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: max > 0 ? value : 0,
                      max: max > 0 ? max : 1,
                      onChanged: max > 0 ? (v) => service.seek(Duration(milliseconds: v.round())) : null,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _clock(total),
                    textAlign: TextAlign.end,
                    style: context.text.labelSmall?.copyWith(color: athar.textMuted),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: service.previous,
                  tooltip: 'recitation_previous'.tr,
                  iconSize: 30,
                  icon: Icon(rtl ? Icons.skip_next_rounded : Icons.skip_previous_rounded),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : IconButton.filled(
                          onPressed: service.togglePlay,
                          tooltip: playing ? 'recitation_pause'.tr : 'recitation_play'.tr,
                          iconSize: 30,
                          icon: Icon(
                            failed
                                ? Icons.refresh_rounded
                                : playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: service.next,
                  tooltip: 'recitation_next'.tr,
                  iconSize: 30,
                  icon: Icon(rtl ? Icons.skip_previous_rounded : Icons.skip_next_rounded),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Lets the reader pick the reciter. The choice is remembered, and a
/// recitation already playing carries on in the new voice.
Future<void> showReciterPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _ReciterPicker(),
  );
}

class _ReciterPicker extends StatefulWidget {
  const _ReciterPicker();

  @override
  State<_ReciterPicker> createState() => _ReciterPickerState();
}

class _ReciterPickerState extends State<_ReciterPicker> {
  final _service = RecitationService.instance;
  late Future<List<Reciter>> _future = _service.reciters();

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scroll) => FutureBuilder<List<Reciter>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || (snap.data ?? const []).isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: athar.textMuted, size: 26),
                    const SizedBox(height: 8),
                    Text(
                      'recitation_reciters_failed'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: athar.textMuted),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _future = _service.reciters()),
                      child: Text('retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          final reciters = snap.data!;
          return Obx(() {
            final selected = _service.reciterFor(_service.selectedSlug.value)?.slug;
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    'recitation_choose'.tr,
                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                for (final r in reciters)
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    selected: r.slug == selected,
                    selectedTileColor: athar.gold.withValues(alpha: 0.12),
                    leading: Icon(
                      r.slug == selected ? Icons.check_circle_rounded : Icons.record_voice_over_outlined,
                      color: r.slug == selected ? athar.gold : athar.textMuted,
                    ),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () {
                      _service.selectReciter(r.slug);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          });
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/quran_surahs.dart';
import '../../../core/design/athar_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_reporter.dart';
import '../../../core/utils/widget_image_exporter.dart';
import '../../../data/providers/api_provider.dart';
import '../quran_ayah_geometry.dart';

/// An ayah's Uthmani text, as the server stores it, and where it comes from.
class AyahText {
  const AyahText(this.text, this.source);

  final String text;
  final String source;
}

final _memo = <AyahRef, AyahText>{};

/// The text of [ayah], fetched once per app run.
Future<AyahText> fetchAyahText(AyahRef ayah) async {
  final held = _memo[ayah];
  if (held != null) return held;

  final res = await Get.find<ApiProvider>().quranAyah(ayah.surah, ayah.ayah);
  final text = (res['text'] ?? '').toString().trim();
  if (text.isEmpty) throw StateError('No text for $ayah');

  final found = AyahText(text, (res['source'] ?? '').toString().trim());
  _memo[ayah] = found;
  return found;
}

String _arabicDigits(int n) =>
    n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

SurahInfo? _surah(int n) => n >= 1 && n <= kQuranSurahs.length ? kQuranSurahs[n - 1] : null;

/// Previews [ayah] as an image card and shares it to other apps.
Future<void> showAyahShareSheet(BuildContext context, AyahRef ayah) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AyahShareSheet(ayah: ayah),
  );
}

class _AyahShareSheet extends StatefulWidget {
  const _AyahShareSheet({required this.ayah});

  final AyahRef ayah;

  @override
  State<_AyahShareSheet> createState() => _AyahShareSheetState();
}

class _AyahShareSheetState extends State<_AyahShareSheet> {
  final _cardKey = GlobalKey();
  late Future<AyahText> _future = _load();
  bool _sharing = false;

  /// The ayah's text. The Quran font ships with the app, so the card is ready
  /// to capture as soon as the text arrives.
  Future<AyahText> _load() => fetchAyahText(widget.ayah);

  String _plain(AyahText t) {
    final name = _surah(widget.ayah.surah)?.nameAr ?? '${widget.ayah.surah}';
    return '﴿${t.text}﴾ [$name: ${_arabicDigits(widget.ayah.ayah)}]';
  }

  Future<void> _share(AyahText t) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final path = await WidgetImageExporter.captureToFile(
        _cardKey,
        filename: 'athar_ayah_${widget.ayah.surah}_${widget.ayah.ayah}.png',
      );
      if (path != null) {
        await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: _plain(t)));
      }
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _copy(AyahText t) async {
    await Clipboard.setData(ClipboardData(text: _plain(t)));
    Get.rawSnackbar(message: 'ayah_card_copied'.tr, duration: const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => FutureBuilder<AyahText>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: athar.textMuted, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'ayah_card_failed'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: athar.textMuted),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: Text('retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          final t = snap.data!;
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                'ayah_card_title'.tr,
                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              // Previewed at the sheet's width; captured at the card's own size.
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: AyahCard(ayah: widget.ayah, text: t.text),
                  ),
                ),
              ),
              // if (t.source.isNotEmpty) ...[
              //   const SizedBox(height: 8),
              //   Text(
              //     'ayah_card_source'.trParams({'source': t.source}),
              //     textAlign: TextAlign.center,
              //     style: context.text.labelSmall?.copyWith(color: athar.textMuted),
              //   ),
              // ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _sharing ? null : () => _share(t),
                      icon: _sharing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share_rounded),
                      label: Text('ayah_card_share'.tr),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copy(t),
                      icon: const Icon(Icons.copy_rounded),
                      label: Text('ayah_card_copy'.tr),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The shareable ayah image: story-friendly portrait (at least 9:16), growing
/// taller for a long ayah, with the text sized to its length.
class AyahCard extends StatelessWidget {
  const AyahCard({super.key, required this.ayah, required this.text});

  final AyahRef ayah;
  final String text;

  static const _gold = AppColors.secondary;

  double get _fontSize {
    final n = text.length;
    if (n < 120) return 28;
    if (n < 300) return 24;
    if (n < 700) return 20;
    if (n < 1400) return 17;
    return 15;
  }

  @override
  Widget build(BuildContext context) {
    final surah = _surah(ayah.surah);
    final number = _arabicDigits(ayah.ayah);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: 360,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 640),
          child: IntrinsicHeight(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryDark, Color(0xFF06281C)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold.withValues(alpha: 0.55), width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                    child: Column(
                      children: [
                        const Text('۞', style: TextStyle(color: _gold, fontSize: 22)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _gold.withValues(alpha: 0.7)),
                          ),
                          child: Text(
                            'سورة ${surah?.nameAr ?? ayah.surah}',
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Text(
                                '$text ﴿$number﴾',
                                textAlign: TextAlign.center,
                                style: AtharTypography.quran(
                                  size: _fontSize,
                                  color: Colors.white,
                                  height: 2.1,
                                ).copyWith(decoration: TextDecoration.none),
                              ),
                            ),
                          ),
                        ),
                        Container(height: 1, color: _gold.withValues(alpha: 0.35)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '${surah?.nameAr ?? ayah.surah} : $number',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const Spacer(),
                            Image.asset('assets/images/logo.png', width: 20, height: 20),
                            const SizedBox(width: 6),
                            const Text(
                              'أثر',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

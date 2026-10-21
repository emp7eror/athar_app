import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/quran_surahs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/api_provider.dart';
import '../../../widgets/share_card/share_card.dart';
import '../../../widgets/share_card/share_card_sheet.dart';
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

SurahInfo? _surah(int n) =>
    n >= 1 && n <= kQuranSurahs.length ? kQuranSurahs[n - 1] : null;

/// Previews [ayah] as an image card — in the reader's chosen design and the
/// app's theme colours — and shares it to other apps.
Future<void> showAyahShareSheet(BuildContext context, AyahRef ayah) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AyahShareLoader(ayah: ayah),
  );
}

/// Loads the ayah's text, then shows the share sheet for it.
class _AyahShareLoader extends StatefulWidget {
  const _AyahShareLoader({required this.ayah});

  final AyahRef ayah;

  @override
  State<_AyahShareLoader> createState() => _AyahShareLoaderState();
}

class _AyahShareLoaderState extends State<_AyahShareLoader> {
  late Future<AyahText> _future = fetchAyahText(widget.ayah);

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;

    return FutureBuilder<AyahText>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return SizedBox(
            height: 320,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: athar.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ayah_card_failed'.tr,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(
                        color: athar.textMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _future = fetchAyahText(widget.ayah)),
                      child: Text('retry'.tr),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final text = snap.data!.text;
        final name =
            _surah(widget.ayah.surah)?.nameAr ?? '${widget.ayah.surah}';
        final number = _arabicDigits(widget.ayah.ayah);

        return ShareCardSheet(
          title: 'ayah_card_title'.tr,
          filename: 'athar_ayah_${widget.ayah.surah}_${widget.ayah.ayah}.png',
          plainText: '﴿$text﴾ [$name: $number]',
          content: ShareCardContent(
            kicker: 'سورة $name',
            text: '$text ﴿$number﴾',
            footer: '$name : $number',
            quranic: true,
          ),
        );
      },
    );
  }
}

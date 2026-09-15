import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/providers/api_provider.dart';

/// One credited source, as the server lists it (`GET /credits`).
class Credit {
  const Credit({
    required this.titleAr,
    required this.titleEn,
    required this.name,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.url,
  });

  factory Credit.fromJson(Map<String, dynamic> j) {
    String s(String key) => (j[key] ?? '').toString().trim();
    return Credit(
      titleAr: s('title_ar'),
      titleEn: s('title_en'),
      name: s('name'),
      descriptionAr: s('description_ar'),
      descriptionEn: s('description_en'),
      url: s('url'),
    );
  }

  final String titleAr;
  final String titleEn;
  final String name;
  final String descriptionAr;
  final String descriptionEn;
  final String url;

  static String _pick(bool ar, String a, String e) => ar ? (a.isNotEmpty ? a : e) : (e.isNotEmpty ? e : a);

  String title(bool ar) => _pick(ar, titleAr, titleEn);
  String description(bool ar) => _pick(ar, descriptionAr, descriptionEn);
}

/// Settings → Credits: the sources the app draws on — the Quran text, tafsir,
/// Mushaf pages and so on — managed in the admin panel.
class CreditsView extends StatefulWidget {
  const CreditsView({super.key});

  @override
  State<CreditsView> createState() => _CreditsViewState();
}

class _CreditsViewState extends State<CreditsView> {
  late Future<List<Credit>> _future = _load();

  Future<List<Credit>> _load() async {
    try {
      final res = await Get.find<ApiProvider>().credits();
      final data = res['credits'];
      return [
        if (data is List)
          for (final item in data)
            if (item is Map) Credit.fromJson(Map<String, dynamic>.from(item)),
      ].where((c) => c.name.isNotEmpty).toList();
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    final athar = context.athar;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('credits'.tr)),
      body: SafeArea(
        child: FutureBuilder<List<Credit>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 40, color: athar.textMuted),
                    const SizedBox(height: 12),
                    Text('credits_load_failed'.tr, style: TextStyle(color: athar.textMuted)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: Text('retry'.tr),
                    ),
                  ],
                ),
              );
            }

            final credits = snap.data ?? const <Credit>[];
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'credits_intro'.tr,
                  style: TextStyle(color: athar.textMuted, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                if (credits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'credits_empty'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: athar.textMuted),
                    ),
                  ),
                for (final c in credits) ...[
                  Material(
                    color: athar.beige,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: c.url.isEmpty ? null : () => _open(c.url),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title(isAr),
                              style: TextStyle(
                                color: athar.textMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            if (c.description(isAr).isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(c.description(isAr), style: const TextStyle(fontSize: 13.5, height: 1.5)),
                            ],
                            if (c.url.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.open_in_new_rounded, size: 15, color: colors.primary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      Uri.tryParse(c.url)?.host.replaceFirst('www.', '') ?? c.url,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

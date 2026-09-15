import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui/athar_ui.dart';
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
/// Mushaf pages, fonts — managed in the admin panel.
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

    return Scaffold(
      appBar: AtharAppBar(title: 'credits'.tr),
      body: SafeArea(
        child: FutureBuilder<List<Credit>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.md, AtharSpace.screen, AtharSpace.xxl),
                children: [
                  for (var i = 0; i < 4; i++)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AtharSpace.sm),
                      child: AtharSkeleton(height: 96, radius: AtharRadius.card),
                    ),
                ],
              );
            }
            if (snap.hasError) {
              return AtharErrorState(
                message: 'credits_load_failed'.tr,
                onRetry: () => setState(() => _future = _load()),
              );
            }

            final credits = snap.data ?? const <Credit>[];
            if (credits.isEmpty) {
              return AtharEmptyState(icon: Icons.volunteer_activism_rounded, title: 'credits_empty'.tr);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, AtharSpace.xxl),
              children: [
                Text(
                  'credits_intro'.tr,
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: AtharSpace.md),
                for (final c in credits) ...[
                  _CreditCard(credit: c, isAr: isAr, onOpen: () => _open(c.url)),
                  const SizedBox(height: AtharSpace.sm),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.credit, required this.isAr, required this.onOpen});

  final Credit credit;
  final bool isAr;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    final description = credit.description(isAr);

    return AtharCard(
      tone: AtharCardTone.surface,
      onTap: credit.url.isEmpty ? null : onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(credit.title(isAr), style: context.type.overline),
          const SizedBox(height: AtharSpace.xxs),
          Text(credit.name, style: context.type.sectionTitle),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AtharSpace.xxs),
            Text(description, style: context.text.bodyMedium),
          ],
          if (credit.url.isNotEmpty) ...[
            const SizedBox(height: AtharSpace.xs),
            Row(
              children: [
                Icon(Icons.open_in_new_rounded, size: AtharSize.iconSm, color: primary),
                const SizedBox(width: AtharSpace.xxs),
                Flexible(
                  child: Text(
                    Uri.tryParse(credit.url)?.host.replaceFirst('www.', '') ?? credit.url,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(color: primary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

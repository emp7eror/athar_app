import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/error_reporter.dart';
import '../../data/models/legal_document_model.dart';

/// Renders a Terms/Privacy document fetched from the backend natively,
/// instead of opening the public web page in a browser. Content is pulled
/// from `GET /legal/terms` or `/legal/privacy` — see LegalContentService on
/// the backend, which mirrors the same Blade pages the web site serves.
class LegalDocumentView extends StatefulWidget {
  const LegalDocumentView({
    super.key,
    required this.fallbackTitle,
    required this.fetch,
  });

  /// Shown in the app bar until the real (bilingual) title has loaded.
  final String fallbackTitle;
  final Future<Map<String, dynamic>> Function() fetch;

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  LegalDocument? _doc;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final res = await widget.fetch();
      setState(() => _doc = LegalDocument.fromJson(res));
    } catch (e) {
      ErrorReporter.report(e, StackTrace.current);
      setState(() => _failed = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    final athar = context.athar;

    return Scaffold(
      appBar: AppBar(
        title: Text(_doc?.title.of(isAr) ?? widget.fallbackTitle),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _failed
                ? _ErrorState(onRetry: _load)
                : _doc == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_doc!.updatedAt.isNotEmpty)
                            Text(
                              '${'last_updated'.tr}: ${_doc!.updatedAt}',
                              style: TextStyle(color: athar.textMuted, fontSize: 12),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _doc!.intro.of(isAr),
                            style: TextStyle(color: athar.textMuted, fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          for (final section in _doc!.sections) ...[
                            _SectionView(section: section, isAr: isAr),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section, required this.isAr});

  final LegalSection section;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading.of(isAr),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final p in section.paragraphs) ...[
          Text(p.of(isAr), style: const TextStyle(fontSize: 14, height: 1.6)),
          const SizedBox(height: 8),
        ],
        if (section.list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in section.list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              color: athar.primaryDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.of(isAr), style: const TextStyle(fontSize: 14, height: 1.6)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (section.note != null)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: athar.beige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              section.note!.of(isAr),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.5),
            ),
          ),
        if (section.email != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: InkWell(
              onTap: () => launchUrl(Uri(scheme: 'mailto', path: section.email)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    section.email!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: context.athar.textMuted),
            const SizedBox(height: 12),
            Text('legal_load_failed'.tr, style: TextStyle(color: context.athar.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text('retry'.tr)),
          ],
        ),
      );
}

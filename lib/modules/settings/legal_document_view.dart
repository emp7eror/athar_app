import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui/athar_ui.dart';
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
    final doc = _doc;

    return Scaffold(
      appBar: AtharAppBar(title: doc?.title.of(isAr) ?? widget.fallbackTitle),
      body: SafeArea(
        child: _loading
            ? const AtharLoadingState()
            : _failed
                ? AtharErrorState(message: 'legal_load_failed'.tr, onRetry: _load)
                : doc == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AtharSpace.screen,
                          AtharSpace.xs,
                          AtharSpace.screen,
                          AtharSpace.xxl,
                        ),
                        children: [
                          if (doc.updatedAt.isNotEmpty)
                            Text('${'last_updated'.tr}: ${doc.updatedAt}', style: context.type.caption),
                          const SizedBox(height: AtharSpace.xs),
                          Text(
                            doc.intro.of(isAr),
                            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: AtharSpace.lg),
                          for (final section in doc.sections) ...[
                            _SectionView(section: section, isAr: isAr),
                            const SizedBox(height: AtharSpace.lg),
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
    final scheme = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(section.heading.of(isAr), style: context.type.sectionTitle),
        ),
        const SizedBox(height: AtharSpace.xs),
        for (final p in section.paragraphs) ...[
          Text(p.of(isAr), style: context.text.bodyMedium),
          const SizedBox(height: AtharSpace.xs),
        ],
        if (section.list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AtharSpace.xxs, bottom: AtharSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in section.list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AtharSpace.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: AtharSpace.sm),
                        Expanded(child: Text(item.of(isAr), style: context.text.bodyMedium)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (section.note != null)
          AtharCard(
            tone: AtharCardTone.surface,
            padding: const EdgeInsets.all(AtharSpace.sm),
            child: Text(section.note!.of(isAr), style: context.type.bodyStrong),
          ),
        if (section.email != null)
          Padding(
            padding: const EdgeInsets.only(top: AtharSpace.xs),
            child: AtharButton(
              label: section.email!,
              icon: Icons.email_rounded,
              variant: AtharButtonVariant.ghost,
              compact: true,
              onPressed: () => launchUrl(Uri(scheme: 'mailto', path: section.email)),
            ),
          ),
      ],
    );
  }
}

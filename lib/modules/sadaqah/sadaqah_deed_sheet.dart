import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../home/home_controller.dart';
import 'sadaqah_controller.dart';
import 'sadaqah_done_dialog.dart';
import 'sadaqah_models.dart';
import 'sadaqah_widgets.dart';

/// One deed in full — what to do, its points, its source and its benefit —
/// with the تصدقت button that records it. Once the server has recorded the
/// deed the sheet closes and the done popup shows, with the points it actually
/// gave; a failure keeps the sheet open to try again.
class SadaqahDeedSheet extends StatefulWidget {
  const SadaqahDeedSheet._(this.deed);

  final SadaqahDeed deed;

  /// Opens [deed]. After a recording: the done popup, then a level reached by
  /// it — one after the other, never stacked.
  static Future<void> open(BuildContext context, SadaqahDeed deed) async {
    final result = await showAtharSheet<SadaqahRecordResult>(
      context: context,
      builder: (_) => SadaqahDeedSheet._(deed),
    );
    if (result == null) return;

    await SadaqahDoneDialog.show(result.pointsAwarded);
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().celebrateLevelUp(result.response);
    }
  }

  @override
  State<SadaqahDeedSheet> createState() => _SadaqahDeedSheetState();
}

class _SadaqahDeedSheetState extends State<SadaqahDeedSheet> {
  final controller = Get.find<SadaqahController>();

  String? _error;

  SadaqahDeed get deed => widget.deed;

  Future<void> _record() async {
    setState(() => _error = null);
    try {
      final result = await controller.record(deed);
      if (result == null || !mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(result);
    } on SadaqahRecordException catch (e) {
      // Nothing was recorded or awarded; the button stays for a safe retry.
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = controller.categoryOf(deed);
    final color = category?.color ?? context.colors.primary;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AtharSpace.lg,
                0,
                AtharSpace.lg,
                AtharSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TitleBlock(deed: deed, color: color, category: category),
                  const SizedBox(height: AtharSpace.lg),
                  _Section(
                    title: 'sadaqah_description'.tr,
                    child: Text(deed.description, style: context.type.body),
                  ),
                  _Section(
                    title: 'sadaqah_points'.tr,
                    child: Row(
                      children: [
                        SadaqahPointsPill(points: deed.points, color: color),
                        const SizedBox(width: AtharSpace.xs),
                        Text(
                          'sadaqah_points_value'.trParams({
                            'points': '${deed.points}',
                          }),
                          style: context.type.bodyStrong,
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'sadaqah_source'.tr,
                    child: _SourceCard(source: deed.source, color: color),
                  ),
                  _Section(
                    title: 'sadaqah_benefit'.tr,
                    child: Text(deed.benefit, style: context.type.body),
                  ),
                  const SadaqahPointsNote(),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AtharSpace.lg,
                AtharSpace.xs,
                AtharSpace.lg,
                AtharSpace.md,
              ),
              child: _actions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Obx(() {
      final busy = controller.recording.value == deed.id;
      final otherBusy = controller.recording.value != null && !busy;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: AtharSize.icon,
                    color: context.colors.error,
                  ),
                  const SizedBox(width: AtharSpace.xs),
                  Expanded(
                    child: Text(
                      _error!,
                      style: context.type.body.copyWith(
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AtharSpace.sm),
          ] else if (controller.rewardedToday.value) ...[
            // Recording again is welcome; it just won't add points today.
            Text(
              'sadaqah_points_taken_note'.tr,
              textAlign: TextAlign.center,
              style: context.type.caption,
            ),
            const SizedBox(height: AtharSpace.xs),
          ],
          AtharButton(
            label: _error == null ? 'sadaqah_confirm'.tr : 'retry'.tr,
            icon: _error == null
                ? Icons.volunteer_activism_rounded
                : Icons.refresh_rounded,
            expand: true,
            loading: busy,
            // Disabled while any deed is being recorded: one request at a time.
            onPressed: busy || otherBusy ? null : _record,
          ),
        ],
      );
    });
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.deed,
    required this.color,
    required this.category,
  });

  final SadaqahDeed deed;
  final Color color;
  final SadaqahCategory? category;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            SadaqahIcons.of(deed.icon),
            size: AtharSize.iconXl - 4,
            color: color,
          ),
        ),
        const SizedBox(width: AtharSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(deed.title, style: context.type.screenTitle),
              ),
              const SizedBox(height: AtharSpace.xxs),
              Text(
                [
                  ?category?.name,
                  if (deed.subcategory.isNotEmpty) deed.subcategory,
                ].join(' · '),
                style: context.type.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        AtharIconButton(
          icon: Icons.close_rounded,
          tooltip: 'sadaqah_close'.tr,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AtharSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.type.overline),
          ),
          const SizedBox(height: AtharSpace.xxs),
          child,
        ],
      ),
    );
  }
}

/// The source as given: its kind, the reference, and the words — exact
/// quotations and paraphrases labelled as what they are, and a text that
/// supports the deed only as a general principle said to be one.
class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.color});

  final SadaqahSource source;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = source.text;

    return Container(
      padding: const EdgeInsets.all(AtharSpace.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AtharRadius.md),
        border: BorderDirectional(start: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line(label: 'sadaqah_source_type'.tr, value: source.type),
          _Line(label: 'sadaqah_source_reference'.tr, value: source.reference),
          if (source.grade != null)
            _Line(label: 'sadaqah_source_grade'.tr, value: source.grade!),
          if (text != null) ...[
            const SizedBox(height: AtharSpace.xs),
            Text(
              source.isQuran ? '﴿$text﴾' : '«$text»',
              style: source.isQuran
                  ? AtharTypography.quran(size: 20, color: scheme.onSurface)
                  : context.type.bodyStrong.copyWith(height: 1.8),
            ),
          ] else if (source.isQuran)
            Padding(
              padding: const EdgeInsets.only(top: AtharSpace.xxs),
              child: Text(
                'sadaqah_verse_by_reference'.tr,
                style: context.type.caption,
              ),
            ),
          if (source.summary != null) ...[
            const SizedBox(height: AtharSpace.xs),
            Text('sadaqah_source_meaning'.tr, style: context.type.overline),
            Text(source.summary!, style: context.type.body),
          ],
          if (!source.isExplicit) ...[
            const SizedBox(height: AtharSpace.xs),
            _Note(
              icon: Icons.lightbulb_outline_rounded,
              text: 'sadaqah_evidence_principle'.tr,
            ),
          ],
          if (!source.verified) ...[
            const SizedBox(height: AtharSpace.xs),
            _Note(
              icon: Icons.pending_outlined,
              text: 'sadaqah_source_review'.tr,
              color: context.athar.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: context.type.caption.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value, style: context.type.caption),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: AtharSize.iconSm, color: c),
        ),
        const SizedBox(width: AtharSpace.xxs),
        Expanded(
          child: Text(text, style: context.type.caption.copyWith(color: c)),
        ),
      ],
    );
  }
}

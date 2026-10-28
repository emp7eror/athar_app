import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../home/home_controller.dart';
import 'sadaqah_controller.dart';
import 'sadaqah_models.dart';
import 'sadaqah_section.dart';

/// One deed in full — what to do, its points, its source and its benefit —
/// with the تصدقت button that records it. The success message appears only
/// once the server has recorded the deed, with the points it actually gave.
class SadaqahDeedSheet extends StatefulWidget {
  const SadaqahDeedSheet._(this.deed, this.onRecorded);

  final SadaqahDeed deed;

  /// Told as soon as the server has recorded the deed — the sheet may then be
  /// closed by a swipe as well as by its button.
  final ValueChanged<SadaqahRecordResult> onRecorded;

  /// Opens [deed]; a level reached by recording it is celebrated once the
  /// sheet has closed, so the two never stack.
  static Future<void> open(BuildContext context, SadaqahDeed deed) async {
    SadaqahRecordResult? result;
    await showAtharSheet<void>(
      context: context,
      builder: (_) => SadaqahDeedSheet._(deed, (r) => result = r),
    );
    final recorded = result;
    if (recorded != null && Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().celebrateLevelUp(recorded.response);
    }
  }

  @override
  State<SadaqahDeedSheet> createState() => _SadaqahDeedSheetState();
}

class _SadaqahDeedSheetState extends State<SadaqahDeedSheet> {
  final controller = Get.find<SadaqahController>();

  SadaqahRecordResult? _result;
  String? _error;

  SadaqahDeed get deed => widget.deed;

  Future<void> _record() async {
    setState(() => _error = null);
    try {
      final result = await controller.record(deed);
      if (result == null || !mounted) return;
      HapticFeedback.mediumImpact();
      widget.onRecorded(result);
      setState(() => _result = result);
    } on SadaqahRecordException catch (e) {
      // Nothing was recorded or awarded; the button stays for a safe retry.
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = controller.categoryOf(deed)?.color ?? context.colors.primary;
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
                  _TitleBlock(
                    deed: deed,
                    color: color,
                    category: controller.categoryOf(deed),
                  ),
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
              child: AnimatedSize(
                duration: AtharMotion.base,
                curve: AtharMotion.standard,
                child: _result != null
                    ? _Success(result: _result!, deed: deed)
                    : _actions(context),
              ),
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
      final recorded = controller.isRecorded(deed.id);

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
          ],
          if (recorded)
            // Once a day per deed; the server would answer a repeat with
            // "already recorded", so the button isn't offered.
            AtharButton(
              label: 'sadaqah_recorded_today'.tr,
              icon: Icons.check_circle_rounded,
              variant: AtharButtonVariant.tonal,
              expand: true,
              onPressed: null,
            )
          else
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

/// تقبّل الله منك — with what the server actually recorded and awarded.
class _Success extends StatelessWidget {
  const _Success({required this.result, required this.deed});

  final SadaqahRecordResult result;
  final SadaqahDeed deed;

  @override
  Widget build(BuildContext context) {
    final success = context.athar.success;
    final message = switch (result.status) {
      'already_recorded' => 'sadaqah_already_recorded'.tr,
      _ when result.pointsAwarded > 0 => 'sadaqah_success_points'.trParams({
        'points': '${result.pointsAwarded}',
      }),
      _ => 'sadaqah_success_limit'.tr,
    };

    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AtharSpace.md),
            decoration: BoxDecoration(
              color: success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AtharRadius.card),
            ),
            child: Column(
              children: [
                Icon(
                  result.alreadyRecorded
                      ? Icons.check_circle_rounded
                      : Icons.volunteer_activism_rounded,
                  size: AtharSize.iconXl,
                  color: success,
                ),
                const SizedBox(height: AtharSpace.xs),
                if (!result.alreadyRecorded)
                  Text(
                    'sadaqah_success_title'.tr,
                    textAlign: TextAlign.center,
                    style: context.type.sectionTitle.copyWith(color: success),
                  ),
                const SizedBox(height: AtharSpace.xxs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.type.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: AtharSpace.sm),
          AtharButton(
            label: 'sadaqah_done'.tr,
            expand: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

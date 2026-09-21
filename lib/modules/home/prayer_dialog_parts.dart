import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import '../../widgets/choice_chip_group.dart';

/// The top of a prayer dialog: an icon tile, the title, an optional badge
/// (such as the points at stake) and a short explanation.
class PrayerDialogHeader extends StatelessWidget {
  const PrayerDialogHeader({
    super.key,
    required this.icon,
    required this.title,
    this.tone = AtharTone.brand,
    this.badge,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final AtharTone tone;
  final Widget? badge;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.lg, AtharSpace.lg, AtharSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tone.background(context),
                  borderRadius: BorderRadius.circular(AtharRadius.md),
                ),
                child: Icon(icon, size: 26, color: tone.foreground(context)),
              ),
              const SizedBox(width: AtharSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(title, style: context.text.titleLarge)),
                    if (badge != null) ...[
                      const SizedBox(height: AtharSpace.xxs),
                      badge!,
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AtharSpace.sm),
            Text(subtitle!, style: context.type.caption),
          ],
        ],
      ),
    );
  }
}

/// One required single-choice question: its label, the choices, and a
/// "choose an answer" line when it was skipped.
class PrayerQuestion<T> extends StatelessWidget {
  const PrayerQuestion({
    super.key,
    required this.label,
    required this.options,
    required this.labels,
    required this.icons,
    required this.selected,
    required this.onSelected,
    this.showError = false,
    this.errorText,
    this.required = true,
  });

  final String label;
  final List<T> options;
  final List<String> labels;
  final List<IconData> icons;
  final T? selected;
  final void Function(T) onSelected;
  final bool showError;
  final String? errorText;

  /// Marks the question with a * . False where an answer is pre-filled and
  /// the user only corrects it if it's wrong.
  final bool required;

  @override
  Widget build(BuildContext context) {
    final error = context.colors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AtharSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(child: Text(label, style: context.type.cardTitle)),
              if (required)
                ExcludeSemantics(
                  child: Text(' *', style: context.type.cardTitle.copyWith(color: error)),
                ),
            ],
          ),
          const SizedBox(height: AtharSpace.sm),
          ChoiceChipGroup<T>(
            options: options,
            labels: labels,
            icons: icons,
            selected: selected,
            onSelected: onSelected,
          ),
          AnimatedSize(
            duration: AtharMotion.base,
            curve: AtharMotion.standard,
            alignment: AlignmentDirectional.topStart,
            child: showError
                ? Padding(
                    padding: const EdgeInsets.only(top: AtharSpace.xs),
                    child: Semantics(
                      liveRegion: true,
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: AtharSize.iconSm, color: error),
                          const SizedBox(width: AtharSpace.xxs),
                          Expanded(
                            child: Text(
                              errorText ?? 'prayer_choice_required'.tr,
                              style: context.text.bodySmall?.copyWith(color: error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Cancel and confirm, pinned under a prayer dialog's scrolling questions.
/// Confirm looks unavailable until everything is answered but stays tappable,
/// so a tap can point out what is missing.
class PrayerDialogActions extends StatelessWidget {
  const PrayerDialogActions({
    super.key,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.ready = true,
  });

  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AtharSpace.lg, AtharSpace.sm, AtharSpace.lg, AtharSpace.lg),
        child: Row(
          children: [
            Expanded(
              child: AtharButton(
                label: 'cancel'.tr,
                variant: AtharButtonVariant.secondary,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: AtharSpace.sm),
            Expanded(
              flex: 2,
              child: AnimatedOpacity(
                opacity: ready ? 1 : 0.55,
                duration: AtharMotion.base,
                child: AtharButton(label: confirmLabel, onPressed: onConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

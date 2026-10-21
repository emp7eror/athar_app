import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'adhkar_models.dart';

/// The actions a card's menu can offer; which ones depends on the item.
enum AdhkarCardAction { share, edit, delete, moveUp, moveDown, reset }

/// One Adhkar or Dua.
///
/// Tapping anywhere on the card counts. The menu, the details toggle and the
/// drag handle take their own taps, so editing, deleting, resetting or
/// reordering can never count by accident. Without [onCount] (a public
/// category, read-only) the card only reads.
class AdhkarCard extends StatefulWidget {
  const AdhkarCard({
    super.key,
    required this.item,
    required this.index,
    required this.count,
    required this.isCurrent,
    this.onCount,
    this.actions = const {},
    this.onAction,
    this.dragHandle,
    this.selected = false,
    this.onSelect,
    this.large = false,
  });

  /// The one-at-a-time view: bigger, centred text.
  final bool large;

  final AdhkarItem item;
  final int index;
  final int count;

  /// The item to read next — set apart.
  final bool isCurrent;

  /// Null: not counted here (public categories are read-only).
  final VoidCallback? onCount;
  final Set<AdhkarCardAction> actions;
  final ValueChanged<AdhkarCardAction>? onAction;

  /// Shown in the header when the list can be reordered.
  final Widget? dragHandle;

  /// Choosing items to copy (public categories): a checkbox takes the menu's
  /// place, and tapping the card toggles it.
  final bool selected;
  final ValueChanged<bool>? onSelect;

  @override
  State<AdhkarCard> createState() => _AdhkarCardState();
}

class _AdhkarCardState extends State<AdhkarCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = context.colors;
    final athar = context.athar;
    final counting = widget.onCount != null;
    final selecting = widget.onSelect != null;
    final done = counting && item.hasTarget && widget.count >= item.target!;
    final radius = BorderRadius.circular(AtharRadius.card);
    final emphasised = widget.isCurrent || widget.selected;

    final borderColor = done
        ? athar.success
        : emphasised
        ? scheme.primary
        : scheme.outlineVariant;

    final background = done
        ? athar.success.withValues(alpha: 0.06)
        : widget.selected
        ? scheme.primaryContainer.withValues(alpha: 0.45)
        : athar.card;

    return AnimatedContainer(
      duration: AtharMotion.base,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(
          color: borderColor,
          width: emphasised || done ? 1.6 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          button: (counting && !done) || selecting,
          selected: selecting ? widget.selected : null,
          hint: counting && !done ? 'adhkar_tap_to_count'.tr : null,
          child: InkWell(
            borderRadius: radius,
            // The whole card is the counter — or, when choosing items, the
            // checkbox.
            onTap: counting && !done
                ? widget.onCount
                : selecting
                ? () => widget.onSelect!(!widget.selected)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, done),
                if (item.occasion != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AtharSpace.md,
                      AtharSpace.xxs,
                      AtharSpace.md,
                      0,
                    ),
                    child: Text(
                      item.occasion!,
                      textAlign: widget.large
                          ? TextAlign.center
                          : TextAlign.start,
                      style: context.type.cardTitle.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AtharSpace.md,
                    widget.large ? AtharSpace.md : AtharSpace.xs,
                    AtharSpace.md,
                    widget.large ? AtharSpace.lg : AtharSpace.md,
                  ),
                  child: Text(
                    item.text,
                    textAlign: widget.large
                        ? TextAlign.center
                        : TextAlign.start,
                    style: context.text.titleMedium?.copyWith(
                      fontSize: widget.large ? 24 : 19,
                      height: 1.9,
                      fontWeight: FontWeight.w500,
                      color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                ),
                if (item.hasDetails) _details(context),
                if (counting) ...[
                  Divider(height: 1, color: scheme.outlineVariant),
                  _counterRow(context, done),
                ] else if (item.hasTarget)
                  _targetInfo(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Read-only cards: how many times the item is said, without a counter.
  Widget _targetInfo(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      AtharSpace.md,
      0,
      AtharSpace.md,
      AtharSpace.md,
    ),
    child: Row(
      children: [
        Icon(
          Icons.repeat_rounded,
          size: AtharSize.iconSm,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: AtharSpace.xxs),
        Text(
          'adhkar_target_info'.trParams({'n': '${widget.item.target}'}),
          style: context.type.caption,
        ),
      ],
    ),
  );

  Widget _header(BuildContext context, bool done) {
    final scheme = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AtharSpace.sm,
        AtharSpace.xs,
        0,
        0,
      ),
      child: Row(
        children: [
          // Absorbs its own taps: grabbing the handle never counts.
          if (widget.dragHandle != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: widget.dragHandle,
            ),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Text('${widget.index + 1}', style: context.text.labelMedium),
          ),
          const SizedBox(width: AtharSpace.xs),
          if (done)
            AtharBadge(
              label: 'adhkar_done'.tr,
              icon: Icons.check_rounded,
              tone: AtharTone.success,
            )
          // Not on the first card: where to start needs no pointer.
          else if (widget.isCurrent && widget.index > 0)
            AtharBadge(
              label: 'adhkar_current'.tr,
              icon: Icons.arrow_forward_rounded,
              tone: AtharTone.brand,
            ),
          const Spacer(),
          if (widget.onSelect != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AtharSpace.xxs),
              child: Checkbox(
                value: widget.selected,
                onChanged: (v) => widget.onSelect!(v ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            )
          else if (widget.actions.isNotEmpty && widget.onAction != null)
            PopupMenuButton<AdhkarCardAction>(
              tooltip: 'adhkar_more'.tr,
              icon: Icon(
                Icons.more_vert_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onSelected: widget.onAction,
              itemBuilder: (_) => [
                for (final a in AdhkarCardAction.values)
                  if (widget.actions.contains(a))
                    PopupMenuItem(
                      value: a,
                      child: Row(
                        children: [
                          Icon(
                            _icon(a),
                            size: AtharSize.icon,
                            color: a == AdhkarCardAction.delete
                                ? scheme.error
                                : null,
                          ),
                          const SizedBox(width: AtharSpace.sm),
                          Text(_label(a)),
                        ],
                      ),
                    ),
              ],
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _details(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AtharSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _showDetails = !_showDetails),
            icon: Icon(
              _showDetails
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: AtharSize.icon,
            ),
            label: Text(
              _showDetails
                  ? 'adhkar_hide_details'.tr
                  : 'adhkar_show_details'.tr,
            ),
          ),
          AnimatedSize(
            duration: AtharMotion.base,
            alignment: AlignmentDirectional.topStart,
            child: !_showDetails
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AtharSpace.xs,
                      0,
                      AtharSpace.xs,
                      AtharSpace.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.reference != null)
                          _detail(
                            context,
                            'adhkar_reference'.tr,
                            item.reference!,
                          ),
                        if (item.virtue != null)
                          _detail(context, 'adhkar_virtue'.tr, item.virtue!),
                        if (item.notes != null)
                          _detail(context, 'adhkar_notes'.tr, item.notes!),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AtharSpace.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.type.overline),
        const SizedBox(height: 2),
        Text(value, style: context.text.bodyMedium?.copyWith(height: 1.7)),
      ],
    ),
  );

  Widget _counterRow(BuildContext context, bool done) {
    final item = widget.item;
    final scheme = context.colors;
    final target = item.target;
    final progress = item.hasTarget
        ? (widget.count / target!).clamp(0.0, 1.0)
        : 0.0;

    final countText = item.hasTarget
        ? 'adhkar_count_of'.trParams({
            'count': '${widget.count}',
            'target': '$target',
          })
        : (widget.count == 0
              ? 'adhkar_no_target'.tr
              : 'adhkar_read_times'.trParams({'count': '${widget.count}'}));

    return Padding(
      padding: const EdgeInsets.all(AtharSpace.sm),
      child: Row(
        children: [
          if (item.hasTarget) ...[
            AtharProgressRing(
              value: progress,
              size: widget.large ? 44 : 36,
              strokeWidth: 3.5,
              color: done ? context.athar.success : scheme.primary,
              child: done
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: context.athar.success,
                    )
                  : null,
            ),
            const SizedBox(width: AtharSpace.sm),
          ],
          Expanded(
            child: Text(
              countText,
              style:
                  (widget.large
                          ? context.text.titleMedium
                          : context.text.bodyMedium)
                      ?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: scheme.onSurfaceVariant,
                      ),
            ),
          ),
          // A quiet reminder of how to count, gone once it is complete.
          if (!done)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: AtharSize.iconSm,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AtharSpace.xxs),
                Text('adhkar_tap_to_count'.tr, style: context.type.caption),
              ],
            ),
        ],
      ),
    );
  }

  static IconData _icon(AdhkarCardAction a) => switch (a) {
    AdhkarCardAction.edit => Icons.edit_rounded,
    AdhkarCardAction.delete => Icons.delete_outline_rounded,
    AdhkarCardAction.moveUp => Icons.arrow_upward_rounded,
    AdhkarCardAction.moveDown => Icons.arrow_downward_rounded,
    AdhkarCardAction.share => Icons.ios_share_rounded,
    AdhkarCardAction.reset => Icons.restart_alt_rounded,
  };

  static String _label(AdhkarCardAction a) => switch (a) {
    AdhkarCardAction.edit => 'adhkar_edit_item'.tr,
    AdhkarCardAction.delete => 'adhkar_delete_item'.tr,
    AdhkarCardAction.moveUp => 'adhkar_move_up'.tr,
    AdhkarCardAction.moveDown => 'adhkar_move_down'.tr,
    AdhkarCardAction.share => 'adhkar_share_item'.tr,
    AdhkarCardAction.reset => 'adhkar_reset_item'.tr,
  };
}

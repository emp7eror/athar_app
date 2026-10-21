import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'quran_controller.dart';

/// Choosing the daily werd: how many pages a day, and what each page earns
/// when the day's points are split across them. Shown the first time the
/// Mushaf opens without a werd, and from the cover whenever it is changed.
class WerdPickerSheet extends StatefulWidget {
  const WerdPickerSheet({super.key, required this.firstTime});

  /// Opened by itself on first use, rather than by the reader.
  final bool firstTime;

  static Future<void> show(BuildContext context, {bool firstTime = false}) =>
      showAtharSheet<void>(
        context: context,
        scrollControlled: false,
        builder: (_) => WerdPickerSheet(firstTime: firstTime),
      );

  @override
  State<WerdPickerSheet> createState() => _WerdPickerSheetState();
}

class _WerdPickerSheetState extends State<WerdPickerSheet> {
  final _controller = Get.find<QuranController>();
  late int? _selected = _controller.werdPages.value;
  bool _saving = false;

  Future<void> _save() async {
    final pages = _selected;
    if (pages == null) return;
    setState(() => _saving = true);
    final ok = await _controller.setWerd(pages);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final daily = _controller.dailyPoints.value;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AtharSpace.lg,
          0,
          AtharSpace.lg,
          AtharSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtharSheetHeader(
              title: widget.firstTime
                  ? 'werd_pick_title_first'.tr
                  : 'werd_pick_title'.tr,
              subtitle: 'werd_pick_sub'.trParams({'points': '$daily'}),
            ),
            for (final pages in _controller.werdOptions) ...[
              _WerdOption(
                pages: pages,
                points: pages > 0 ? daily ~/ pages : 0,
                selected: pages == _selected,
                onTap: () => setState(() => _selected = pages),
              ),
              const SizedBox(height: AtharSpace.xs),
            ],
            const SizedBox(height: AtharSpace.sm),
            FilledButton(
              onPressed: _selected == null || _saving ? null : _save,
              child: _saving
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text('save'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _WerdOption extends StatelessWidget {
  const _WerdOption({
    required this.pages,
    required this.points,
    required this.selected,
    required this.onTap,
  });

  final int pages;
  final int points;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtharRadius.md),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AtharSpace.md,
            vertical: AtharSpace.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  werdPagesLabel(pages),
                  style: context.type.cardTitle,
                ),
              ),
              Text(
                'werd_points_each'.trParams({'points': '$points'}),
                style: context.text.bodySmall?.copyWith(
                  color: context.athar.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AtharSpace.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: AtharSize.iconLg,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "1 page", "2 pages", "5 pages"… in the reader's language.
String werdPagesLabel(int pages) => switch (pages) {
  1 => 'werd_pages_1'.tr,
  2 => 'werd_pages_2'.tr,
  _ => 'werd_pages_n'.trParams({'n': '$pages'}),
};

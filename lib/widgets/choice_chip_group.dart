import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Emoji + label chip picker shared by the prayer dialogs (difficulty, mood,
/// missed-reason). Colours come from the active theme so it reads correctly in
/// both light and dark mode — the dialogs used to hardcode light-theme values,
/// which turned the chips into bright blobs on a dark surface.
class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    super.key,
    required this.options,
    required this.labels,
    required this.emojis,
    required this.selected,
    required this.onSelected,
  });

  final List<T> options;
  final List<String> labels;
  final List<String> emojis;

  /// Nullable so pickers that start empty (missed-reason) can share this.
  final T? selected;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final athar = context.athar;

    return Wrap(
      spacing: 3,
      runSpacing: 5,
      children: List.generate(options.length, (i) {
        final isSelected = options[i] == selected;
        return ChoiceChip(
          label: Text('${emojis[i]}  ${labels[i]}'),
          selected: isSelected,
          onSelected: (_) => onSelected(options[i]),
          backgroundColor: athar.beige,
          selectedColor: colors.primary.withValues(alpha: 0.18),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.5),
          ),
          labelStyle: TextStyle(
            color: isSelected ? colors.primary : colors.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
          showCheckmark: false,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      }),
    );
  }
}

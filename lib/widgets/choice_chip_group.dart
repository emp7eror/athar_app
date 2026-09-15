import 'package:flutter/material.dart';

import '../core/ui/athar_ui.dart';

/// Icon + label single-choice picker shared by the prayer dialogs (place,
/// congregation, mood, difficulty, missed reason). Nullable selection so a
/// picker can start empty and require a deliberate answer.
class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    super.key,
    required this.options,
    required this.labels,
    required this.icons,
    required this.selected,
    required this.onSelected,
  });

  final List<T> options;
  final List<String> labels;
  final List<IconData> icons;
  final T? selected;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AtharSpace.xs,
      runSpacing: AtharSpace.xs,
      children: [
        for (var i = 0; i < options.length; i++)
          AtharChoiceChip(
            label: labels[i],
            icon: icons[i],
            selected: options[i] == selected,
            onSelected: () => onSelected(options[i]),
          ),
      ],
    );
  }
}

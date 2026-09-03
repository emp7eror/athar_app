import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Male/female picker used at registration and in profile editing.
///
/// Gender is not cosmetic here: Arabic level titles and any notification
/// about the user in the third person agree with it grammatically
/// (المواظب / المواظبة, قام / قامت).
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// 'male' | 'female' | null when not chosen yet.
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option(context, 'male', 'gender_male'.tr, Icons.male_rounded),
        const SizedBox(width: 10),
        _option(context, 'female', 'gender_female'.tr, Icons.female_rounded),
      ],
    );
  }

  Widget _option(BuildContext context, String key, String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final selected = value == key;

    return Expanded(
      child: Material(
        color: selected ? colors.primary.withValues(alpha: 0.14) : colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onChanged(key),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.primary : colors.outline,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? colors.primary : colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

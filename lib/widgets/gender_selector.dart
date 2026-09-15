import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/ui/athar_ui.dart';

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
    return AtharSegmented<String?>(
      selected: value,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      segments: [
        AtharSegment(value: 'male', label: 'gender_male'.tr, icon: Icons.male_rounded),
        AtharSegment(value: 'female', label: 'gender_female'.tr, icon: Icons.female_rounded),
      ],
    );
  }
}

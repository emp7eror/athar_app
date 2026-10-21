import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../widgets/share_card/share_card.dart';
import '../../widgets/share_card/share_card_sheet.dart';
import 'adhkar_models.dart';

String _arabicDigits(int n) =>
    n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

/// «يُقال مرتين», «يُقال ٣ مرات», «يُقال ١٠٠ مرة» — none for a single time.
String? _repetitions(int? target) {
  if (target == null || target <= 1) return null;
  if (target == 2) return 'يُقال مرتين';
  final n = _arabicDigits(target);
  return target <= 10 ? 'يُقال $n مرات' : 'يُقال $n مرة';
}

/// Shares [item] as an image card, with its text for apps that take text.
Future<void> shareAdhkarItem(
  BuildContext context,
  AdhkarItem item,
  AdhkarCollection collection,
) {
  final occasion = item.occasion;
  // The heading only when it says more than the collection's name.
  final title = occasion != null && occasion != collection.name
      ? occasion
      : null;
  final badge = _repetitions(item.target);

  final plain = [
    ?title,
    item.text,
    ?badge,
    if (item.reference != null) '[${item.reference}]',
    'share_card_via'.tr,
  ].join('\n\n');

  return showShareCardSheet(
    context,
    title: collection.type == AdhkarType.dua
        ? 'share_card_title_dua'.tr
        : 'share_card_title_dhikr'.tr,
    filename: 'athar_${collection.type.name}_${item.key}.png',
    plainText: plain,
    content: ShareCardContent(
      kicker: collection.name,
      title: title,
      text: item.text,
      badge: badge,
      footer: item.reference,
      note: item.virtue,
    ),
  );
}

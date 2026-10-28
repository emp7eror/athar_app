import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/athar_ui.dart';
import 'sadaqah_controller.dart';
import 'sadaqah_models.dart';
import 'sadaqah_widgets.dart';

/// One category's deeds, opened from the صدقة grid. A deed opens in full,
/// where it can be recorded.
class SadaqahCategoryView extends GetView<SadaqahController> {
  const SadaqahCategoryView({super.key, required this.category});

  final SadaqahCategory category;

  static Future<void> open(SadaqahCategory category) async {
    await Get.to(() => SadaqahCategoryView(category: category));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AtharAppBar(title: category.name),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          final deeds = controller.deedsOf(category.key);
          // Read here so a recorded deed's mark updates at once.
          final recorded = controller.recordedToday.toSet();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AtharSpace.screen,
              AtharSpace.md,
              AtharSpace.screen,
              AtharSpace.xl,
            ),
            children: [
              if (deeds.isEmpty)
                SadaqahPanel(
                  child: AtharEmptyState(
                    icon: SadaqahIcons.of(category.icon),
                    title: 'sadaqah_category_empty'.tr,
                    message: 'sadaqah_category_empty_message'.tr,
                  ),
                )
              else
                for (final deed in deeds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AtharSpace.xs),
                    child: SadaqahDeedCard(
                      deed: deed,
                      color: category.color,
                      recorded: recorded.contains(deed.id),
                    ),
                  ),
              const SizedBox(height: AtharSpace.sm),
              const SadaqahPointsNote(),
            ],
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../tour/app_tours.dart';
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
      appBar: AtharAppBar(
        title: category.name,
        actions: const [TourHelpButton(pageId: TourPages.sadaqahCategory, style: TourHelpStyle.appBar)],
      ),
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
                for (final (i, deed) in deeds.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AtharSpace.xs),
                    child: _first(
                      i == 0,
                      SadaqahDeedCard(
                        deed: deed,
                        color: category.color,
                        recorded: recorded.contains(deed.id),
                      ),
                    ),
                  ),
              const SizedBox(height: AtharSpace.sm),
              const TourTarget(id: TourTargets.sadaqahCategoryPoints, child: SadaqahPointsNote()),
            ],
          );
        }),
      ),
    );
  }

  /// The first deed is what the tour points at, and it starts the tour once
  /// there is one to point at.
  Widget _first(bool first, Widget card) => first
      ? TourAutoStart(
          pageId: TourPages.sadaqahCategory,
          child: TourTarget(id: TourTargets.sadaqahDeed, child: card),
        )
      : card;
}

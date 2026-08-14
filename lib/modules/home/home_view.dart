import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localization_controller.dart';
import '../../data/models/prayer_log_model.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Obx(() => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('app_name'.tr,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      IconButton(
                        icon: const Icon(Icons.language),
                        onPressed: Get.find<LocalizationController>().toggle,
                      ),
                    ],
                  ),
                  _nextPrayerCard(),
                  const SizedBox(height: 16),
                  if (controller.quote.isNotEmpty) _quoteCard(),
                  const SizedBox(height: 16),
                  Text('today'.tr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...controller.checklist.map(_prayerTile),
                ],
              )),
        ),
      ),
    );
  }

  Widget _nextPrayerCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          Text('next_prayer'.tr, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Obx(() => Text(controller.nextPrayerKey.value.tr,
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
          const SizedBox(height: 6),
          Obx(() => Text(controller.countdown.value,
              style: const TextStyle(color: AppColors.accent, fontSize: 32, letterSpacing: 2))),
          const SizedBox(height: 8),
          Obx(() => Text('${'points'.tr}: ${controller.pointsToday.value} / 180',
              style: const TextStyle(color: Colors.white70))),
        ]),
      );

  Widget _quoteCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Obx(() => Text('"${controller.quote.value}"',
              style: const TextStyle(fontSize: 15, height: 1.5, fontStyle: FontStyle.italic))),
          Obx(() => controller.quoteSource.value.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('— ${controller.quoteSource.value}',
                      style: const TextStyle(color: AppColors.textMuted)))),
        ]),
      );

  Widget _prayerTile(PrayerChecklistItem item) {
    final active = controller.isActive(item.prayerName);
    return Obx(() {
      final busy = controller.marking.value == item.prayerName;
      final done = item.isCompleted;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: done ? AppColors.success.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: done ? AppColors.success : Colors.transparent, width: 1.2),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.prayerName.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('+${item.points} ${'points'.tr}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ),
          if (busy)
            const SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else if (done)
            const Icon(Icons.check_circle, color: AppColors.success, size: 28)
          else
            GestureDetector(
              onTap: active ? () => controller.mark(item) : null,
              child: Icon(
                active ? Icons.radio_button_unchecked : Icons.lock_outline,
                color: active ? AppColors.primary : AppColors.textMuted,
                size: 28,
              ),
            ),
        ]),
      );
    });
  }
}

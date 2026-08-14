import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../home/home_view.dart';
import '../home/home_binding.dart';
import '../friends/friends_view.dart';
import '../friends/friends_binding.dart';
import '../leaderboard/leaderboard_view.dart';
import '../leaderboard/leaderboard_binding.dart';
import '../stats/stats_view.dart';
import '../stats/stats_binding.dart';

class ShellController extends GetxController {
  final index = 0.obs;
}

class ShellView extends StatelessWidget {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    // Bind all tab controllers up-front so state survives tab switches.
    HomeBinding().dependencies();
    FriendsBinding().dependencies();
    LeaderboardBinding().dependencies();
    StatsBinding().dependencies();
    final c = Get.put(ShellController());

    const pages = [HomeView(), FriendsView(), LeaderboardView(), StatsView()];

    return Obx(() => Scaffold(
          body: IndexedStack(index: c.index.value, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: c.index.value,
            onDestinationSelected: (i) => c.index.value = i,
            indicatorColor: AppColors.primary.withValues(alpha:0.15),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), label: 'home'.tr),
              NavigationDestination(icon: const Icon(Icons.people_outline), label: 'friends'.tr),
              NavigationDestination(
                  icon: const Icon(Icons.leaderboard_outlined), label: 'leaderboard'.tr),
              NavigationDestination(
                  icon: const Icon(Icons.bar_chart_outlined), label: 'stats'.tr),
            ],
          ),
        ));
  }
}

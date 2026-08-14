import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          extendBody: true,
          body: IndexedStack(index: c.index.value, children: pages),
          bottomNavigationBar: _FloatingNavBar(
            index: c.index.value,
            onSelected: (i) => c.index.value = i,
          ),
        ));
  }
}

/// Minimal floating nav bar with a rounded card body and an emerald
/// pill indicator behind the active destination.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.home_rounded, 'home'.tr),
      (Icons.people_alt_rounded, 'friends'.tr),
      (Icons.leaderboard_rounded, 'leaderboard'.tr),
      (Icons.bar_chart_rounded, 'stats'.tr),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].$1,
                  label: items[i].$2,
                  selected: i == index,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? Colors.white : const Color(0xFF9A9A9A)),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

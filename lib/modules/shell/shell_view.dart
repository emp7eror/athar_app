import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_view.dart';
import '../home/home_binding.dart';
import '../friends/friends_view.dart';
import '../friends/friends_binding.dart';
import '../leaderboard/leaderboard_view.dart';
import '../leaderboard/leaderboard_binding.dart';
import '../profile/profile_binding.dart';
import '../profile/profile_view.dart';
import '../settings/settings_view.dart';
import '../stats/stats_view.dart';
import '../stats/stats_binding.dart';

class ShellController extends GetxController {
  final index = 0.obs;

  /// Index of the tab we consider "root" for the back-button contract.
  /// Back from any other tab returns here first; a second back then exits.
  static const homeTabIndex = 0;
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
    ProfileBinding().dependencies();
    final c = Get.put(ShellController());

    const pages = [HomeView(), FriendsView(), LeaderboardView(), StatsView(), ProfileView(),
      SettingsView()];

    return Obx(() {
      // ── Android back-button contract ──
      // A pushed detail route (e.g. NotificationSettings) is NOT this widget;
      // Navigator pops it natively before this PopScope ever runs. So here we
      // only handle the root case:
      //   * non-home tab → switch to home tab (soft back)
      //   * home tab     → exit the app
      final onHome = c.index.value == ShellController.homeTabIndex;
      return PopScope(
        canPop: onHome, // let the system pop (→ app exit) only from home
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (!onHome) {
            c.index.value = ShellController.homeTabIndex;
          } else {
            // Belt-and-suspenders: on some OEMs canPop:true isn't honored on
            // the first invocation, so explicitly exit as well.
            await SystemNavigator.pop();
          }
        },
        // ── Store-based update check via `upgrader` ──
        // Non-intrusive: dialog only appears when the store reports a newer
        // version. Language flips with the app locale.
        child: UpgradeAlert(
          showIgnore: false,
          showLater: false,
          shouldPopScope: () => false,
          upgrader: Upgrader(
            messages: UpgraderMessages(
              code: Get.locale?.languageCode == 'ar' ? 'ar' : 'en',
            ),
            // Respect a per-session dedup so we don't nag users who dismissed
            // the dialog already this launch.
            durationUntilAlertAgain: const Duration(days: 3),
          ),
          child: Scaffold(
            extendBody: true,
            body: IndexedStack(index: c.index.value, children: pages),
            bottomNavigationBar: _FloatingNavBar(
              index: c.index.value,
              onSelected: (i) => c.index.value = i,
            ),
          ),
        ),
      );
    });
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
      (Icons.person_outline, 'profile'.tr),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).extension<AtharPalette>()!.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
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
    final muted = Theme.of(context).extension<AtharPalette>()!.textMuted;
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
            Icon(icon, size: 20, color: selected ? Colors.white : muted),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white,fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

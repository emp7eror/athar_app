import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';

import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../coach/coach_binding.dart';
import '../coach/coach_view.dart';
import '../friends/friends_binding.dart';
import '../friends/friends_view.dart';
import '../home/home_binding.dart';
import '../home/home_view.dart';
import '../leaderboard/leaderboard_binding.dart';
import '../leaderboard/leaderboard_view.dart';
import '../profile/profile_binding.dart';
import '../profile/profile_view.dart';
import '../stats/stats_binding.dart';
import '../stats/stats_view.dart';
import '../tour/app_tours.dart';

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

    // Settings is a pushed screen, opened from Home.
    const pages = [HomeView(), FriendsView(), LeaderboardView(), StatsView(), ProfileView()];

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
            // Starts a tab's product tour the first time that tab is selected
            // (all tabs stay mounted, so it can't be done on build).
            body: TourTabAutoStart(
              index: c.index,
              tabs: TourPages.shellTabs,
              child: IndexedStack(index: c.index.value, children: pages),
            ),
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

/// A floating bar of five destinations, each always labelled, with the AI
/// coach raised on its centre.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  /// The coach button's size, and how far it dips into the bar's padding.
  static const _aiSize = 52.0;
  static const _aiOverlap = 22.0;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.home_rounded, 'home'.tr),
      (Icons.people_alt_rounded, 'friends'.tr),
      (Icons.leaderboard_rounded, 'leaderboard'.tr),
      (Icons.bar_chart_rounded, 'stats'.tr),
      (Icons.person_rounded, 'profile'.tr),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AtharSpace.md, 0, AtharSpace.md, AtharSpace.md),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: _aiSize - _aiOverlap),
              child: TourTarget(
                id: TourTargets.shellNav,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AtharSpace.xs, vertical: AtharSpace.xs),
                  decoration: BoxDecoration(
                    color: context.athar.card,
                    borderRadius: BorderRadius.circular(AtharRadius.sheet),
                    border: Border.all(color: context.colors.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavItem(
                            icon: items[i].$1,
                            label: items[i].$2,
                            selected: i == index,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const TourTarget(id: TourTargets.shellCoach, child: _AiButton(size: _aiSize)),
          ],
        ),
      ),
    );
  }
}

/// The AI coach, raised on top of the nav bar instead of set among the tabs,
/// so it is one tap away from every tab.
class _AiButton extends StatelessWidget {
  const _AiButton({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final athar = context.athar;

    return Tooltip(
      message: 'coach_title'.tr,
      child: Semantics(
        button: true,
        label: 'coach_title'.tr,
        child: Material(
          type: MaterialType.transparency,
          elevation: 6,
          shadowColor: Colors.black45,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Get.to(() => const CoachView(), binding: CoachBinding()),
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: athar.heroGradient,
                // A ring in the bar's colour, so the button reads as sitting on
                // the bar rather than floating over the page.
                border: Border.all(color: athar.card, width: 4),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
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
    final scheme = context.colors;
    final muted = scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtharRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AtharSpace.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AtharMotion.base,
                curve: AtharMotion.standard,
                padding: const EdgeInsets.symmetric(horizontal: AtharSpace.md, vertical: AtharSpace.xxs + 2),
                decoration: BoxDecoration(
                  color: selected ? scheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(AtharRadius.pill),
                ),
                child: Icon(
                  icon,
                  size: AtharSize.icon,
                  color: selected ? scheme.onPrimaryContainer : muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: selected ? scheme.onSurface : muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

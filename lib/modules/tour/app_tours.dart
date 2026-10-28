import 'package:flutter/material.dart';

import '../../core/tour/tour_models.dart';

/// Page ids used for tours (and as their saved completion keys).
abstract final class TourPages {
  static const home = 'home';
  static const friends = 'friends';
  static const leaderboard = 'leaderboard';
  static const stats = 'stats';
  static const profile = 'profile';
  static const settings = 'settings';
  static const dhikr = 'dhikr';
  static const quran = 'quran';
  static const adhkar = 'adhkar';
  static const coach = 'coach';
  static const adhkarCollection = 'adhkar_collection';

  /// The shell's IndexedStack order — index → page id.
  static const shellTabs = [home, friends, leaderboard, stats, settings];
}

/// Ids of the `TourTarget` widgets placed in the UI.
abstract final class TourTargets {
  // Shell — visible on every tab
  static const shellNav = 'shell.nav';
  static const shellCoach = 'shell.coach';

  // Home
  static const homeProfile = 'home.profile';
  static const homeNextPrayer = 'home.nextPrayer';
  static const homePrayers = 'home.prayers';
  static const homePractices = 'home.practices';
  static const homeSettings = 'home.settings';

  // Friends
  static const friendsCode = 'friends.code';
  static const friendsAdd = 'friends.add';
  static const friendsFirst = 'friends.first';

  // Leaderboard
  static const leaderboardMetric = 'leaderboard.metric';
  static const leaderboardFilters = 'leaderboard.filters';
  static const leaderboardFirst = 'leaderboard.first';

  // Stats
  static const statsSummary = 'stats.summary';
  static const statsLevel = 'stats.level';
  static const statsWeekly = 'stats.weekly';
  static const statsMonthly = 'stats.monthly';

  // Profile
  static const profileAvatar = 'profile.avatar';
  static const profileInfo = 'profile.info';
  static const profileLogout = 'profile.logout';

  // Settings
  static const settingsProfile = 'settings.profile';
  static const settingsCalcMethod = 'settings.calcMethod';
  static const settingsLocation = 'settings.location';
  static const settingsLanguage = 'settings.language';
  static const settingsTheme = 'settings.theme';
  static const settingsReminders = 'settings.reminders';

  // Dhikr
  static const dhikrSelector = 'dhikr.selector';
  static const dhikrCounter = 'dhikr.counter';
  static const dhikrBeads = 'dhikr.beads';
  static const dhikrVirtue = 'dhikr.virtue';
  static const dhikrShake = 'dhikr.shake';

  // Quran
  static const quranContinue = 'quran.continue';
  static const quranStats = 'quran.stats';
  static const quranWays = 'quran.ways';
  static const quranWerd = 'quran.werd';

  // AI coach
  static const coachBadge = 'coach.badge';
  static const coachTitle = 'coach.title';
  static const coachFirstCard = 'coach.firstCard';

  // Adhkar & Duas
  static const adhkarSearch = 'adhkar.search';
  static const adhkarReminders = 'adhkar.reminders';
  static const adhkarTabs = 'adhkar.tabs';
  static const adhkarMine = 'adhkar.mine';
  static const adhkarCategories = 'adhkar.categories';

  // One of the reader's own Adhkar & Duas collections
  static const adhkarCount = 'adhkarCollection.count';
  static const adhkarCollectionReminders = 'adhkarCollection.reminders';
  static const adhkarView = 'adhkarCollection.view';
  static const adhkarMenu = 'adhkarCollection.menu';

  /// The Help (?) button of a page (see `TourHelpButton.targetId`).
  static String help(String pageId) => '$pageId.help';
}

/// Every page's tour. Add a step here and a matching `TourTarget` in the UI;
/// nothing else changes. A step can also switch tabs first with
/// `navigateTo: TourPages.<tab>` — the tour returns to its own page when done.
abstract final class AppTours {
  static List<PageTour> get all => [
        home,
        friends,
        leaderboard,
        stats,
        profile,
        settings,
        dhikr,
        quran,
        adhkar,
        adhkarCollection,
        coach,
      ];

  static final home = PageTour(
    pageId: TourPages.home,
    isTab: true,
    steps: [
      const TourStep(
        target: TourTargets.homeProfile,
        titleKey: 'tour_home_profile_title',
        bodyKey: 'tour_home_profile_body',
        icon: Icons.person_rounded,
        padding: 6,
      ),
      const TourStep(
        target: TourTargets.homeSettings,
        titleKey: 'tour_home_settings_title',
        bodyKey: 'tour_home_settings_body',
        icon: Icons.settings_outlined,
        shape: TourShape.circle,
        padding: 4,
      ),
      const TourStep(
        target: TourTargets.homeNextPrayer,
        titleKey: 'tour_home_next_title',
        bodyKey: 'tour_home_next_body',
        icon: Icons.mosque_outlined,
        radius: 26,
        padding: 4,
      ),
      const TourStep(
        target: TourTargets.homePrayers,
        titleKey: 'tour_home_prayers_title',
        bodyKey: 'tour_home_prayers_body',
        icon: Icons.check_circle_outline_rounded,
      ),
      const TourStep(
        target: TourTargets.homePractices,
        titleKey: 'tour_home_practices_title',
        bodyKey: 'tour_home_practices_body',
        icon: Icons.auto_stories_outlined,
        radius: 22,
      ),
      const TourStep(
        target: TourTargets.shellCoach,
        titleKey: 'tour_home_coach_title',
        bodyKey: 'tour_home_coach_body',
        icon: Icons.auto_awesome_rounded,
        shape: TourShape.circle,
        padding: 6,
      ),
      const TourStep(
        target: TourTargets.shellNav,
        titleKey: 'tour_home_nav_title',
        bodyKey: 'tour_home_nav_body',
        icon: Icons.explore_outlined,
        radius: 30,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.help(TourPages.home),
        titleKey: 'tour_help_title',
        bodyKey: 'tour_help_body',
        icon: Icons.help_outline_rounded,
        shape: TourShape.circle,
        padding: 4,
      ),
    ],
  );

  static const friends = PageTour(
    pageId: TourPages.friends,
    isTab: true,
    steps: [
      TourStep(
        target: TourTargets.friendsCode,
        titleKey: 'tour_friends_code_title',
        bodyKey: 'tour_friends_code_body',
        icon: Icons.qr_code_2_rounded,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.friendsAdd,
        titleKey: 'tour_friends_add_title',
        bodyKey: 'tour_friends_add_body',
        icon: Icons.person_add_alt_rounded,
      ),
      TourStep(
        target: TourTargets.friendsFirst,
        titleKey: 'tour_friends_list_title',
        bodyKey: 'tour_friends_list_body',
        icon: Icons.notifications_active_outlined,
      ),
    ],
  );

  static const leaderboard = PageTour(
    pageId: TourPages.leaderboard,
    isTab: true,
    steps: [
      TourStep(
        target: TourTargets.leaderboardMetric,
        titleKey: 'tour_lb_metric_title',
        bodyKey: 'tour_lb_metric_body',
        icon: Icons.star_outline_rounded,
      ),
      TourStep(
        target: TourTargets.leaderboardFilters,
        titleKey: 'tour_lb_filters_title',
        bodyKey: 'tour_lb_filters_body',
        icon: Icons.tune_rounded,
      ),
      TourStep(
        target: TourTargets.leaderboardFirst,
        titleKey: 'tour_lb_list_title',
        bodyKey: 'tour_lb_list_body',
        icon: Icons.emoji_events_outlined,
      ),
    ],
  );

  static const stats = PageTour(
    pageId: TourPages.stats,
    isTab: true,
    steps: [
      TourStep(
        target: TourTargets.statsSummary,
        titleKey: 'tour_stats_summary_title',
        bodyKey: 'tour_stats_summary_body',
        icon: Icons.dashboard_outlined,
      ),
      TourStep(
        target: TourTargets.statsLevel,
        titleKey: 'tour_stats_level_title',
        bodyKey: 'tour_stats_level_body',
        icon: Icons.emoji_events_outlined,
      ),
      TourStep(
        target: TourTargets.statsWeekly,
        titleKey: 'tour_stats_weekly_title',
        bodyKey: 'tour_stats_weekly_body',
        icon: Icons.bar_chart_rounded,
      ),
      TourStep(
        target: TourTargets.statsMonthly,
        titleKey: 'tour_stats_monthly_title',
        bodyKey: 'tour_stats_monthly_body',
        icon: Icons.calendar_month_outlined,
      ),
    ],
  );

  static const profile = PageTour(
    pageId: TourPages.profile,
    steps: [
      TourStep(
        target: TourTargets.profileAvatar,
        titleKey: 'tour_profile_avatar_title',
        bodyKey: 'tour_profile_avatar_body',
        icon: Icons.photo_camera_outlined,
        shape: TourShape.circle,
      ),
      TourStep(
        target: TourTargets.profileInfo,
        titleKey: 'tour_profile_info_title',
        bodyKey: 'tour_profile_info_body',
        icon: Icons.badge_outlined,
      ),
      TourStep(
        target: TourTargets.profileLogout,
        titleKey: 'tour_profile_logout_title',
        bodyKey: 'tour_profile_logout_body',
        icon: Icons.logout_rounded,
      ),
    ],
  );

  static const settings = PageTour(
    pageId: TourPages.settings,
    isTab: true,
    steps: [
      TourStep(
        target: TourTargets.settingsProfile,
        titleKey: 'tour_settings_profile_title',
        bodyKey: 'tour_settings_profile_body',
        icon: Icons.person_outline_rounded,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.settingsTheme,
        titleKey: 'tour_settings_theme_title',
        bodyKey: 'tour_settings_theme_body',
        icon: Icons.palette_outlined,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.settingsLanguage,
        titleKey: 'tour_settings_language_title',
        bodyKey: 'tour_settings_language_body',
        icon: Icons.language_outlined,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.settingsLocation,
        titleKey: 'tour_settings_location_title',
        bodyKey: 'tour_settings_location_body',
        icon: Icons.location_on_outlined,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.settingsCalcMethod,
        titleKey: 'tour_settings_calc_title',
        bodyKey: 'tour_settings_calc_body',
        icon: Icons.calculate_outlined,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.settingsReminders,
        titleKey: 'tour_settings_reminders_title',
        bodyKey: 'tour_settings_reminders_body',
        icon: Icons.notifications_outlined,
        padding: 4,
      ),
    ],
  );

  static const dhikr = PageTour(
    pageId: TourPages.dhikr,
    steps: [
      TourStep(
        target: TourTargets.dhikrSelector,
        titleKey: 'tour_dhikr_selector_title',
        bodyKey: 'tour_dhikr_selector_body',
        icon: Icons.swap_horiz_rounded,
        radius: 30,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.dhikrCounter,
        titleKey: 'tour_dhikr_counter_title',
        bodyKey: 'tour_dhikr_counter_body',
        icon: Icons.donut_large_rounded,
        shape: TourShape.circle,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.dhikrBeads,
        titleKey: 'tour_dhikr_beads_title',
        bodyKey: 'tour_dhikr_beads_body',
        icon: Icons.touch_app_outlined,
      ),
      TourStep(
        target: TourTargets.dhikrShake,
        titleKey: 'tour_dhikr_shake_title',
        bodyKey: 'tour_dhikr_shake_body',
        icon: Icons.vibration_rounded,
        shape: TourShape.circle,
        padding: 2,
      ),
      TourStep(
        target: TourTargets.dhikrVirtue,
        titleKey: 'tour_dhikr_virtue_title',
        bodyKey: 'tour_dhikr_virtue_body',
        icon: Icons.auto_stories_outlined,
        shape: TourShape.circle,
        padding: 2,
      ),
    ],
  );

  static const quran = PageTour(
    pageId: TourPages.quran,
    steps: [
      TourStep(
        target: TourTargets.quranContinue,
        titleKey: 'tour_quran_continue_title',
        bodyKey: 'tour_quran_continue_body',
        icon: Icons.bookmark_outline_rounded,
      ),
      TourStep(
        target: TourTargets.quranWerd,
        titleKey: 'tour_quran_werd_title',
        bodyKey: 'tour_quran_werd_body',
        icon: Icons.menu_book_outlined,
        radius: 20,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.quranWays,
        titleKey: 'tour_quran_ways_title',
        bodyKey: 'tour_quran_ways_body',
        icon: Icons.explore_outlined,
      ),
      TourStep(
        target: TourTargets.quranStats,
        titleKey: 'tour_quran_stats_title',
        bodyKey: 'tour_quran_stats_body',
        icon: Icons.insights_outlined,
      ),
    ],
  );

  static final adhkar = PageTour(
    pageId: TourPages.adhkar,
    steps: [
      const TourStep(
        target: TourTargets.adhkarSearch,
        titleKey: 'tour_adhkar_search_title',
        bodyKey: 'tour_adhkar_search_body',
        icon: Icons.search_rounded,
        shape: TourShape.circle,
        padding: 4,
      ),
      const TourStep(
        target: TourTargets.adhkarReminders,
        titleKey: 'tour_adhkar_reminders_title',
        bodyKey: 'tour_adhkar_reminders_body',
        icon: Icons.notifications_outlined,
        shape: TourShape.circle,
        padding: 4,
      ),
      const TourStep(
        target: TourTargets.adhkarTabs,
        titleKey: 'tour_adhkar_tabs_title',
        bodyKey: 'tour_adhkar_tabs_body',
        icon: Icons.tab_outlined,
      ),
      const TourStep(
        target: TourTargets.adhkarMine,
        titleKey: 'tour_adhkar_mine_title',
        bodyKey: 'tour_adhkar_mine_body',
        icon: Icons.collections_bookmark_outlined,
        padding: 4,
      ),
      const TourStep(
        target: TourTargets.adhkarCategories,
        titleKey: 'tour_adhkar_categories_title',
        bodyKey: 'tour_adhkar_categories_body',
        icon: Icons.library_add_outlined,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.help(TourPages.adhkar),
        titleKey: 'tour_help_title',
        bodyKey: 'tour_help_body',
        icon: Icons.help_outline_rounded,
        shape: TourShape.circle,
        padding: 4,
      ),
    ],
  );

  static const adhkarCollection = PageTour(
    pageId: TourPages.adhkarCollection,
    steps: [
      TourStep(
        target: TourTargets.adhkarCount,
        titleKey: 'tour_adhkar_count_title',
        bodyKey: 'tour_adhkar_count_body',
        icon: Icons.touch_app_outlined,
      ),
      TourStep(
        target: TourTargets.adhkarCollectionReminders,
        titleKey: 'tour_adhkar_col_reminders_title',
        bodyKey: 'tour_adhkar_col_reminders_body',
        icon: Icons.alarm_rounded,
        shape: TourShape.circle,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.adhkarView,
        titleKey: 'tour_adhkar_view_title',
        bodyKey: 'tour_adhkar_view_body',
        icon: Icons.view_carousel_outlined,
        shape: TourShape.circle,
        padding: 4,
      ),
      TourStep(
        target: TourTargets.adhkarMenu,
        titleKey: 'tour_adhkar_menu_title',
        bodyKey: 'tour_adhkar_menu_body',
        icon: Icons.more_vert_rounded,
        shape: TourShape.circle,
        padding: 4,
      ),
    ],
  );

  static final coach = PageTour(
    pageId: TourPages.coach,
    steps: [
      const TourStep(
        target: TourTargets.coachBadge,
        titleKey: 'tour_coach_badge_title',
        bodyKey: 'tour_coach_badge_body',
        icon: Icons.auto_awesome_rounded,
        radius: 20,
        padding: 4,
      ),
      const TourStep(
        target: TourTargets.coachTitle,
        titleKey: 'tour_coach_title_title',
        bodyKey: 'tour_coach_title_body',
        icon: Icons.workspace_premium_outlined,
      ),
      const TourStep(
        target: TourTargets.coachFirstCard,
        titleKey: 'tour_coach_card_title',
        bodyKey: 'tour_coach_card_body',
        icon: Icons.insights_outlined,
      ),
      TourStep(
        target: TourTargets.help(TourPages.coach),
        titleKey: 'tour_help_title',
        bodyKey: 'tour_help_body',
        icon: Icons.help_outline_rounded,
        shape: TourShape.circle,
        padding: 4,
      ),
    ],
  );
}

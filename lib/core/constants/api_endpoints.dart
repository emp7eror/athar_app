class ApiEndpoints {
  // Point this at your Laravel host. Use 10.0.2.2 for Android emulator -> localhost.
  static const String baseUrl = 'https://athar.ferasmelhem.com/api';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String anonymousLogin = '/auth/anonymous';
  static const String logout = '/auth/logout';
  static const String fcmToken = '/auth/fcm-token';
  static const String location = '/user/location';
  static const String timezone = '/user/timezone';

  static const String prayersToday = '/prayers/today';
  static const String markPrayer = '/prayers/mark';

  static const String dhikrToday = '/dhikr/today';
  static const String dhikrIncrement = '/dhikr/increment';

  static const String quranWerd = '/quran/werd';
  static const String quranPageOpen = '/quran/page-open';
  static const String quranPageComplete = '/quran/page-complete';
  static const String quranMoods = '/quran/moods';
  static const String quranMoodSuggestions = '/quran/moods/more';
  static const String quranFeelings = '/quran/feelings';
  static const String quranFeelingPersonal = '/quran/feelings/personal';

  static const String friends = '/friends';
  static const String addFriend = '/friends/add';
  static const String addFriendById = '/friends/add-by-id';
  static const String respondFriend = '/friends/respond';
  static const String removeFriend = '/friends/remove';
  static const String nudge = '/friends/nudge';

  static String userProfile(int id) => '/users/$id/profile';

  static const String stats = '/stats';
  static const String statsInsights = '/stats/insights';
  static const String leaderboard = '/leaderboard';
  static const String randomQuote = '/quotes/random';

  static const String legalTerms = '/legal/terms';
  static const String legalPrivacy = '/legal/privacy';
}

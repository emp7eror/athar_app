class ApiEndpoints {
  // Point this at your Laravel host. Use 10.0.2.2 for Android emulator -> localhost.
  static const String baseUrl = 'https://athar.ferasmelhem.com/api';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String anonymousLogin = '/auth/anonymous';
  static const String passwordForgot = '/auth/password/forgot';
  static const String passwordVerify = '/auth/password/verify';
  static const String passwordReset = '/auth/password/reset';
  static const String logout = '/auth/logout';
  static const String deleteAccount = '/account';
  static const String fcmToken = '/auth/fcm-token';
  static const String location = '/user/location';
  /// Public: setting a location by name is the way in when the device's own
  /// location is unavailable.
  static const String cities = '/cities';
  static const String timezone = '/user/timezone';

  static const String prayersToday = '/prayers/today';
  static const String markPrayer = '/prayers/mark';

  static const String dhikrToday = '/dhikr/today';
  static const String dhikrIncrement = '/dhikr/increment';

  static const String quranWerd = '/quran/werd';

  // Adhkar & Duas (separate from the tasbeeh counters).
  static const String adhkarLibrary = '/adhkar/library';
  static const String adhkarMine = '/adhkar/mine';
  static const String adhkarMyCollections = '/adhkar/my/collections';
  static const String adhkarCopyCollection = '/adhkar/my/collections/copy';
  static String adhkarMyCollection(int id) => '/adhkar/my/collections/$id';
  static String adhkarMyCollectionOrder(int id) => '/adhkar/my/collections/$id/order';
  static String adhkarMyCollectionItems(int id) => '/adhkar/my/collections/$id/items';
  static String adhkarMyItem(int id) => '/adhkar/my/items/$id';
  static const String adhkarProgress = '/adhkar/progress';
  static const String adhkarSync = '/adhkar/progress/sync';
  static const String quranTafsirs = '/quran/tafsirs';
  static const String quranReciters = '/quran/reciters';
  static String quranAyah(int surah, int ayah) => '/quran/ayahs/$surah/$ayah';
  static const String quranPageComplete = '/quran/page-complete';
  static const String quranPageTime = '/quran/page-time';
  static const String quranMoods = '/quran/moods';
  static const String quranMoodSuggestions = '/quran/moods/more';
  static const String quranFeelings = '/quran/feelings';
  static const String quranFeelingPersonal = '/quran/feelings/personal';
  static const String sadaqah = '/sadaqah';
  static const String sadaqahMine = '/sadaqah/mine';
  static String sadaqahDeed(int id) => '/sadaqah/deeds/$id';
  static String sadaqahRecord(int id) => '/sadaqah/deeds/$id/record';

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
  static const String credits = '/credits';
  static const String legalPrivacy = '/legal/privacy';
}

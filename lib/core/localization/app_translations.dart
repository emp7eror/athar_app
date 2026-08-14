import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ar': {
          'app_name': 'أثر',
          'fajr': 'الفجر', 'dhuhr': 'الظهر', 'asr': 'العصر',
          'maghrib': 'المغرب', 'isha': 'العشاء',
          'points': 'النقاط', 'streak': 'سلسلة الصلوات', 'level': 'المستوى',
          'nudge': 'تذكير', 'yes_prayed': 'نعم صليت',
          'will_pray_soon': 'حسناً سأصلي', 'will_not_pray': 'لا أريد الصلاة',
          'friend_prayed_msg': '@name قام بأداء صلاة @prayer الآن!',
          'today': 'اليوم', 'friends': 'الأصدقاء', 'leaderboard': 'المتصدرون',
          'stats': 'الإحصائيات', 'home': 'الرئيسية',
          'next_prayer': 'الصلاة القادمة', 'time_left': 'الوقت المتبقي',
          'add_friend': 'إضافة صديق', 'enter_code': 'أدخل رمز الصديق',
          'streaks_tab': 'السلاسل', 'points_tab': 'النقاط',
          'login': 'تسجيل الدخول', 'register': 'إنشاء حساب',
          'email': 'البريد الإلكتروني', 'password': 'كلمة المرور',
          'name': 'الاسم', 'age': 'العمر', 'logout': 'تسجيل الخروج',
          'your_code': 'رمزك', 'daily_progress': 'تقدم اليوم',
          'window_closed': 'خارج وقت الصلاة',
        },
        'en': {
          'app_name': 'Athar',
          'fajr': 'Fajr', 'dhuhr': 'Dhuhr', 'asr': 'Asr',
          'maghrib': 'Maghrib', 'isha': 'Isha',
          'points': 'Points', 'streak': 'Prayer Streak', 'level': 'Level',
          'nudge': 'Nudge', 'yes_prayed': 'Yes, I prayed',
          'will_pray_soon': 'I will pray soon', 'will_not_pray': "I won't pray",
          'friend_prayed_msg': '@name completed @prayer prayer now!',
          'today': 'Today', 'friends': 'Friends', 'leaderboard': 'Leaderboard',
          'stats': 'Stats', 'home': 'Home',
          'next_prayer': 'Next Prayer', 'time_left': 'Time left',
          'add_friend': 'Add Friend', 'enter_code': 'Enter friend code',
          'streaks_tab': 'Streaks', 'points_tab': 'Points',
          'login': 'Log in', 'register': 'Sign up',
          'email': 'Email', 'password': 'Password',
          'name': 'Name', 'age': 'Age', 'logout': 'Log out',
          'your_code': 'Your code', 'daily_progress': "Today's progress",
          'window_closed': 'Outside prayer window',
        }
      };
}

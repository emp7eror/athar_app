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
          'location_not_set': 'لم يتم تحديد الموقع',
          'location_updated': 'تم تحديث الموقع',
          'update_location': 'تحديث الموقع',
          'location_error': 'تعذّر تحديد الموقع',
          'location_services_disabled': 'خدمة الموقع غير مُفعّلة',
          'location_permission_denied': 'تم رفض إذن الوصول إلى الموقع',
          // ── Onboarding ──────────────────────────────────────────
          'skip': 'تخطّي',
          'next': 'التالي',
          'begin_journey': 'ابدأ رحلتك',
          'ob1_title': 'لِكُلِّ صَلَاةٍ.. أَثَر',
          'ob1_sub':
              'الصلاة ليست مجرد روتين، بل هي نقطة التحول التي تمنح يومك السكينة والبركة.',
          'ob2_title': 'أدومُها وإن قلّ',
          'ob2_sub':
              'نساعدك على بناء عادة الصلاة وتتبع أثرها الإيجابي خطوة بخطوة دون ضغط أو إرهاق.',
          'ob3_title': 'سَكِينَةٌ وَسَطَ صَخَبِ الحَيَاة',
          'ob3_sub':
              'استرجع صفاء ذهنك، واجعل مواقيت الصلاة محطات متجددة للراحة والتأمل الروحي.',
          'ob4_title': 'شَاهِدْ أثَرَ صَلَاتِكَ',
          'ob4_sub':
              'سجل مشاعرك وانعكاس الصلاة على سلوكك ويومك لترى كيف تتغير حياتك للأفضل.',
          'ob5_title': 'ابْدَأْ أَثَرِكَ اليَوْم',
          'ob5_sub':
              'انضم إلى مجتمع يسعى للسكينة والارتقاء الروحي. ابدأ خطوتك الأولى الآن.',
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
          'location_not_set': 'Location not set',
          'location_updated': 'Location updated',
          'update_location': 'Update location',
          'location_error': 'Could not get location',
          'location_services_disabled': 'Location services are off',
          'location_permission_denied': 'Location permission denied',
          // ── Onboarding ──────────────────────────────────────────
          'skip': 'Skip',
          'next': 'Next',
          'begin_journey': 'Begin Journey',
          'ob1_title': 'Every Prayer Leaves an Impact',
          'ob1_sub':
              'Prayer isn\'t just a routine—it\'s the turning point that fills your day with peace and purpose.',
          'ob2_title': 'Consistency Over Perfection',
          'ob2_sub':
              'Build a lasting prayer habit step by step, tracking your spiritual progress effortlessly.',
          'ob3_title': 'Tranquility in a Busy World',
          'ob3_sub':
              'Pause the noise. Turn your prayer times into refreshing moments of clarity and reflection.',
          'ob4_title': 'Witness Your Growth',
          'ob4_sub':
              'Reflect on your daily journey and see how spiritual mindfulness enriches your everyday actions.',
          'ob5_title': 'Start Your Journey Today',
          'ob5_sub':
              'Join a mindful community striving for spiritual growth and peace. Take your first step now.',
        }
      };
}

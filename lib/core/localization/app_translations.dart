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
          // ── Permissions ─────────────────────────────────────────
          'perm_location_title': 'السماح بالوصول إلى الموقع',
          'perm_location_msg':
              'نحتاج إلى إذن الموقع لتوفير الميزات التي تعتمد على موقعك ومساعدتك على استخدام التطبيق بشكل أفضل.',
          'perm_location_cta': 'السماح بالوصول',
          'perm_notif_title': 'السماح بالإشعارات',
          'perm_notif_msg':
              'اسمح لنا بإرسال التنبيهات المهمة ومواعيد الصلاة والتذكيرات لمساعدتك على المحافظة على صلاتك.',
          'perm_notif_cta': 'السماح بالإشعارات',
          'perm_try_again': 'إعادة المحاولة',
          'perm_open_settings': 'فتح الإعدادات',
          'perm_required_note': 'هذا الإذن مطلوب لمتابعة استخدام التطبيق.',
          'perm_denied_note':
              'لم يتم منح الإذن. يرجى السماح به للمتابعة.',
          'perm_permanent_note':
              'تم رفض الإذن نهائياً. يرجى تفعيله يدوياً من إعدادات النظام للمتابعة.',
          'perm_restricted_note':
              'هذا الإذن مقيّد على هذا الجهاز ولا يمكن تفعيله.',
          'perm_service_off_note':
              'خدمة الموقع غير مُفعّلة على جهازك. يرجى تفعيلها للمتابعة.',
          'perm_step': 'الخطوة @current من @total',
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
          // ── Permissions ─────────────────────────────────────────
          'perm_location_title': 'Allow Location Access',
          'perm_location_msg':
              'We need location permission to provide features that depend on your location and help you use the app better.',
          'perm_location_cta': 'Allow Access',
          'perm_notif_title': 'Allow Notifications',
          'perm_notif_msg':
              'Let us send important alerts, prayer times, and reminders to help you stay consistent with your prayers.',
          'perm_notif_cta': 'Allow Notifications',
          'perm_try_again': 'Try Again',
          'perm_open_settings': 'Open Settings',
          'perm_required_note': 'This permission is required to continue using the app.',
          'perm_denied_note': 'Permission was not granted. Please allow it to continue.',
          'perm_permanent_note':
              'Permission was permanently denied. Please enable it manually from system settings to continue.',
          'perm_restricted_note':
              'This permission is restricted on this device and cannot be enabled.',
          'perm_service_off_note':
              'Location services are turned off on your device. Please enable them to continue.',
          'perm_step': 'Step @current of @total',
        }
      };
}

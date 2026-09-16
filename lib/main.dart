import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'core/bindings/initial_binding.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/localization_controller.dart';
import 'core/services/notification_router.dart';
import 'core/services/prayer_notification_scheduler.dart';
import 'core/services/timezone_service.dart';
import 'data/providers/storage_provider.dart';
import 'core/design/athar_scale.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/error_reporter.dart';
import 'firebase_options.dart';
import 'modules/auth/auth_view.dart';
import 'modules/auth/auth_binding.dart';
import 'modules/onboarding/onboarding_view.dart';
import 'modules/onboarding/onboarding_binding.dart';
import 'modules/permissions/permission_binding.dart';
import 'modules/permissions/permission_gate_view.dart';
import 'modules/shell/shell_view.dart';
import 'modules/splash/splash_binding.dart';
import 'modules/splash/splash_view.dart';

/// The bundled fonts are under the SIL Open Font License, which travels with
/// them.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    const fonts = {
      'IBM Plex Sans Arabic': 'assets/fonts/OFL-IBMPlexSansArabic.txt',
      'Inter': 'assets/fonts/OFL-Inter.txt',
      'Amiri Quran': 'assets/fonts/OFL-AmiriQuran.txt',
    };
    for (final entry in fonts.entries) {
      yield LicenseEntryWithLineBreaks([entry.key], await rootBundle.loadString(entry.value));
    }
  });
}

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Keep this minimal — no GetX/UI here; the isolate has no widget tree.
}

/// Picks the avatar through the Android system photo picker instead of the
/// gallery intent. The picker hands back only the item the user chose, so the
/// app needs no READ_MEDIA_IMAGES permission — which Google Play's photo and
/// video permissions policy reserves for apps the pickers can't serve. A no-op
/// off Android.
void _useSystemPhotoPicker() {
  final picker = ImagePickerPlatform.instance;
  if (picker is ImagePickerAndroid) picker.useAndroidPhotoPicker = true;
}

Future<void> main() async {
  ErrorReporter.init();
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  _useSystemPhotoPicker();

  // Portrait only. AndroidManifest and Info.plist lock it natively before the
  // first frame; this keeps Flutter in agreement.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  await GetStorage.init();

  // Register singletons before the first frame so language/session/services
  // are ready. Async services (notifications, timezone, audio) are awaited so
  // the scheduler can safely use them.
  InitialBinding().dependencies();
  await InitialBinding.initAsync();

  // Lay out the first batch of prayer notifications. Self-guards on
  // permission, so it's safe even before the user grants it.
  unawaited(Get.find<PrayerNotificationScheduler>().reschedule());

  // Tap routing for a background (app in memory) or cold-started (terminated)
  // FCM notification tap. Foreground taps are handled separately by
  // NotificationService's local-notification response callback.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    NotificationRouter.routeFromData(message.data);
  });
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    NotificationRouter.routeFromData(initialMessage.data);
  }

  runApp(const AtharApp());
}

class AtharApp extends StatefulWidget {
  const AtharApp({super.key});

  @override
  State<AtharApp> createState() => _AtharAppState();
}

class _AtharAppState extends State<AtharApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Top up the multi-day schedule (and pick up any prayer-time drift /
    // timezone change) every time the app returns to the foreground.
    if (state == AppLifecycleState.resumed &&
        Get.isRegistered<PrayerNotificationScheduler>()) {
      Get.find<PrayerNotificationScheduler>().reschedule();

      // Catches a timezone change that happened while backgrounded (travel).
      // Guarded on an active session — an unauthenticated call would 401 and
      // the interceptor would sign the user out.
      if (Get.isRegistered<TimezoneService>() &&
          Get.isRegistered<StorageProvider>() &&
          Get.find<StorageProvider>().isLoggedIn) {
        Get.find<TimezoneService>().syncIfChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.find<LocalizationController>();

    // Rebuilt when an appearance preference changes; a language change
    // rebuilds the whole tree too, which picks up the Arabic or Latin type.
    return GetBuilder<ThemeController>(
      builder: (themeCtrl) => GetMaterialApp(
      title: 'Athar',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: lang.locale,
      fallbackLocale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      theme: themeCtrl.lightTheme(arabic: lang.isRtl),
      darkTheme: themeCtrl.darkTheme(arabic: lang.isRtl),
      themeMode: themeCtrl.mode,
      // The reader's text & interface size, on top of the device's own.
      builder: (context, child) => AtharScaleScope(
        size: themeCtrl.textSize,
        child: child ?? const SizedBox.shrink(),
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(
          name: '/splash',
          page: () => const SplashView(),
          binding: SplashBinding(),
        ),
        GetPage(
          name: '/onboarding',
          page: () => const OnboardingView(),
          binding: OnboardingBinding(),
        ),
        GetPage(
          name: '/permissions',
          page: () => const PermissionGateView(),
          binding: PermissionBinding(),
        ),
        GetPage(name: '/auth', page: () => const AuthView(), binding: AuthBinding()),
        GetPage(name: '/home', page: () => const ShellView()),
      ],
      ),
    );
  }
}

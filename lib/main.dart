import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/bindings/initial_binding.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/localization_controller.dart';
import 'core/services/notification_router.dart';
import 'core/services/prayer_notification_scheduler.dart';
import 'core/services/timezone_service.dart';
import 'data/providers/storage_provider.dart';
import 'core/theme/app_theme.dart';
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

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Keep this minimal — no GetX/UI here; the isolate has no widget tree.
}

Future<void> main() async {
  ErrorReporter.init();
  WidgetsFlutterBinding.ensureInitialized();

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
    final themeCtrl = Get.find<ThemeController>();

    return GetMaterialApp(
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeCtrl.mode,
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
    );
  }
}

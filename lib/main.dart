import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/bindings/initial_binding.dart';
import 'core/constants/app_colors.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/localization_controller.dart';
import 'data/providers/storage_provider.dart';
import 'firebase_options.dart';
import 'modules/auth/auth_view.dart';
import 'modules/auth/auth_binding.dart';
import 'modules/shell/shell_view.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Keep this minimal — no GetX/UI here; the isolate has no widget tree.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  await GetStorage.init();
  runApp(const AtharApp());
}

class AtharApp extends StatelessWidget {
  const AtharApp({super.key});

  @override
  Widget build(BuildContext context) {
    // InitialBinding must run before we read persisted language/session.
    InitialBinding().dependencies();
    final lang = Get.find<LocalizationController>();
    final storage = Get.find<StorageProvider>();

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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'Cairo', // add the font to pubspec assets for full RTL polish
      ),
      initialRoute: storage.isLoggedIn ? '/home' : '/auth',
      getPages: [
        GetPage(name: '/auth', page: () => const AuthView(), binding: AuthBinding()),
        GetPage(name: '/home', page: () => const ShellView()),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/services/timezone_service.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/snackbar.dart';
import '../../core/utils/store_link.dart';
import '../../data/providers/api_provider.dart';
import '../home/home_controller.dart';
import 'legal_document_view.dart';
import 'notification_settings_view.dart';
import '../../core/tour/tour_widgets.dart';
import '../tour/app_tours.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang    = Get.find<LocalizationController>();
    final theme   = Get.find<ThemeController>();
    final home    = Get.find<HomeController>();
    final colors  = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          // Keeps the whole page built so tour steps can scroll to any tile.
          scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('settings'.tr,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const TourHelpButton(pageId: TourPages.settings),
              ],
            ),
            const SizedBox(height: 24),

            _SectionHeader('general'.tr),
            const SizedBox(height: 12),

            TourTarget(
              id: TourTargets.settingsLocation,
              child: _SettingsTile(
              icon: Icons.location_on_outlined,
              title: 'location'.tr,
              trailing: Obx(() => home.updatingLocation.value
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      home.locationLabel.value,
                      style: TextStyle(
                          color: colors.primary, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    )),
              onTap: () {
                if (!home.updatingLocation.value) home.updateLocation();
              },
            ),
            ),

            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.schedule_outlined,
              title: 'timezone'.tr,
              trailing: Obx(() => Text(
                Get.find<TimezoneService>().current.value.isEmpty
                    ? '-'
                    : Get.find<TimezoneService>().current.value,
                style: TextStyle(
                    color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              )),
              // Detected automatically; tapping re-checks and reports a change
              // (the server allows one change per day).
              onTap: () => Get.find<TimezoneService>().syncIfChanged(),
            ),

            const SizedBox(height: 24),

            _SectionHeader('appearance'.tr),
            const SizedBox(height: 12),

            TourTarget(
              id: TourTargets.settingsLanguage,
              child: _SettingsTile(
              icon: Icons.language_outlined,
              title: 'language'.tr,
              trailing: Obx(() => Text(
                lang.currentLang.value == 'ar' ? 'العربية' : 'English',
                style: TextStyle(
                    color: colors.primary, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              )),
              onTap: lang.toggle,
            ),
            ),

            const SizedBox(height: 8),

            TourTarget(
              id: TourTargets.settingsTheme,
              child: _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'theme'.tr,
              trailing: GetBuilder<ThemeController>(
                builder: (t) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.isDark ? 'dark'.tr : 'light'.tr,
                      style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      t.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: colors.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ),
              onTap: theme.toggle,
            ),
            ),

            const SizedBox(height: 24),

            _SectionHeader('notifications'.tr),
            const SizedBox(height: 12),

            TourTarget(
              id: TourTargets.settingsReminders,
              child: _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'prayer_reminders'.tr,
                trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                onTap: () => Get.to(() => const NotificationSettingsView()),
              ),
            ),

            const SizedBox(height: 24),

            _SectionHeader('about'.tr),
            const SizedBox(height: 12),

            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final label = info == null ? '' : '${info.version}+${info.buildNumber}';
                return _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'app_version'.tr,
                  trailing: Text(label,
                      style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  // Tapping opens this app's store listing — Play Store on
                  // Android, App Store on iOS — so the user can check for and
                  // install an update.
                  onTap: () async {
                    final opened = await StoreLink.open();
                    if (!opened) {
                      AppSnackbar.error('app_version'.tr, 'open_store_failed'.tr);
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'privacy_policy'.tr,
              trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              onTap: () => Get.to(() => LegalDocumentView(
                    fallbackTitle: 'privacy_policy'.tr,
                    fetch: () => Get.find<ApiProvider>().legalPrivacy(),
                  )),
            ),

            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'terms'.tr,
              trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              onTap: () => Get.to(() => LegalDocumentView(
                    fallbackTitle: 'terms'.tr,
                    fetch: () => Get.find<ApiProvider>().legalTerms(),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData      icon;
  final String        title;
  final Widget        trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, color: colors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: trailing,
            ),
          ]),
        ),
      ),
    );
  }
}
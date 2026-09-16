import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/localization/localization_controller.dart';
import '../../core/services/timezone_service.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/tour/tour_widgets.dart';
import '../../core/ui/athar_ui.dart';
import '../../core/utils/snackbar.dart';
import '../../core/utils/store_link.dart';
import '../../data/providers/api_provider.dart';
import '../home/home_controller.dart';
import '../tour/app_tours.dart';
import 'appearance_view.dart';
import 'credits_view.dart';
import 'legal_document_view.dart';
import 'notification_settings_view.dart';

/// Settings, opened from Home: appearance & language, prayer & location, and
/// about — each a group of rows rather than a card per setting.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static String appearanceSummary(ThemeController t) {
    final mode = switch (t.appearance) {
      AppearanceMode.system => 'mode_system'.tr,
      AppearanceMode.light => 'light'.tr,
      AppearanceMode.dark => 'dark'.tr,
    };
    return '${t.preset.nameKey.tr} · $mode · ${t.textSize.labelKey.tr}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.find<LocalizationController>();
    final home = Get.find<HomeController>();
    final timezone = Get.find<TimezoneService>();

    return TourAutoStart(
      pageId: TourPages.settings,
      child: Scaffold(
        appBar: AtharAppBar(
          title: 'settings'.tr,
          actions: const [
            TourHelpButton(pageId: TourPages.settings, style: TourHelpStyle.appBar),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AtharSpace.screen,
            AtharSpace.xs,
            AtharSpace.screen,
            AtharSpace.xxl,
          ),
          // Keeps the whole page built so tour steps can scroll to any row.
          scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
          children: [
            AtharListGroup(
              title: 'settings_group_appearance'.tr,
              children: [
                TourTarget(
                  id: TourTargets.settingsTheme,
                  child: GetBuilder<ThemeController>(
                    builder: (t) => AtharListRow(
                      icon: Icons.palette_rounded,
                      title: 'appearance'.tr,
                      subtitle: appearanceSummary(t),
                      onTap: () => Get.to(() => const AppearanceView()),
                    ),
                  ),
                ),
                TourTarget(
                  id: TourTargets.settingsLanguage,
                  child: Obx(
                    () => AtharListRow(
                      icon: Icons.translate_rounded,
                      title: 'language'.tr,
                      value: lang.currentLang.value == 'ar' ? 'العربية' : 'English',
                      showChevron: false,
                      onTap: lang.toggle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AtharSpace.lg),
            AtharListGroup(
              title: 'settings_group_prayer'.tr,
              children: [
                TourTarget(
                  id: TourTargets.settingsLocation,
                  child: Obx(() {
                    final updating = home.updatingLocation.value;
                    return AtharListRow(
                      icon: Icons.location_on_rounded,
                      title: 'location'.tr,
                      value: updating ? null : home.locationLabel.value,
                      trailing: updating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      showChevron: false,
                      onTap: updating ? null : () => home.updateLocation(),
                    );
                  }),
                ),
                Obx(
                  () => AtharListRow(
                    icon: Icons.schedule_rounded,
                    title: 'timezone'.tr,
                    value: timezone.current.value.isEmpty ? '-' : timezone.current.value,
                    showChevron: false,
                    // Detected automatically; tapping re-checks and reports a
                    // change (the server allows one change per day).
                    onTap: () => timezone.syncIfChanged(),
                  ),
                ),
                TourTarget(
                  id: TourTargets.settingsReminders,
                  child: AtharListRow(
                    icon: Icons.notifications_rounded,
                    title: 'prayer_reminders'.tr,
                    onTap: () => Get.to(() => const NotificationSettingsView()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AtharSpace.lg),
            AtharListGroup(
              title: 'about'.tr,
              children: [
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    return AtharListRow(
                      icon: Icons.info_rounded,
                      // tone: AtharTone.neutral,
                      title: 'app_version'.tr,
                      value: info == null ? '' : '${info.version}+${info.buildNumber}',
                      showChevron: false,
                      // Opens this app's store listing to check for an update.
                      onTap: () async {
                        final opened = await StoreLink.open();
                        if (!opened) {
                          AppSnackbar.error('app_version'.tr, 'open_store_failed'.tr);
                        }
                      },
                    );
                  },
                ),
                AtharListRow(
                  icon: Icons.privacy_tip_rounded,
                  // tone: AtharTone.neutral,
                  title: 'privacy_policy'.tr,
                  onTap: () => Get.to(() => LegalDocumentView(
                        fallbackTitle: 'privacy_policy'.tr,
                        fetch: () => Get.find<ApiProvider>().legalPrivacy(),
                      )),
                ),
                AtharListRow(
                  icon: Icons.description_rounded,
                  // tone: AtharTone.neutral,
                  title: 'terms'.tr,
                  onTap: () => Get.to(() => LegalDocumentView(
                        fallbackTitle: 'terms'.tr,
                        fetch: () => Get.find<ApiProvider>().legalTerms(),
                      )),
                ),
                AtharListRow(
                  icon: Icons.volunteer_activism_rounded,
                  // tone: AtharTone.gold,
                  title: 'credits'.tr,
                  onTap: () => Get.to(() => const CreditsView()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

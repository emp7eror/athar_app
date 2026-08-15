import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/localization/localization_controller.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/snackbar.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang    = Get.find<LocalizationController>();
    final theme   = Get.find<ThemeController>();
    final colors  = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('settings'.tr,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _SectionHeader('appearance'.tr),
            const SizedBox(height: 12),

            _SettingsTile(
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

            const SizedBox(height: 8),

            _SettingsTile(
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

            const SizedBox(height: 24),

            _SectionHeader('notifications'.tr),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'prayer_reminders'.tr,
              trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              onTap: () => AppSnackbar.show('settings'.tr, 'coming_soon'.tr),
            ),

            const SizedBox(height: 24),

            _SectionHeader('about'.tr),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.info_outline,
              title: 'app_version'.tr,
              trailing: Text('1.0.0',
                  style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              onTap: null,
            ),

            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'privacy_policy'.tr,
              trailing: Icon(Icons.open_in_new,
                  color: colors.onSurfaceVariant, size: 18),
              onTap: () {},
            ),

            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'terms'.tr,
              trailing: Icon(Icons.open_in_new,
                  color: colors.onSurfaceVariant, size: 18),
              onTap: () {},
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
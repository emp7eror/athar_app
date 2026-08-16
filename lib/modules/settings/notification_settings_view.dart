import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/notification_sounds.dart';
import '../../core/services/notification_service.dart';
import 'notification_settings_controller.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(NotificationSettingsController());
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('notification_settings'.tr)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: c.refreshStatus,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Obx(() => c.status.value == NotifStatus.ready
                  ? const SizedBox.shrink()
                  : _DisabledBanner(onOpen: c.openSystemSettings)),

              _Header('prayer_notifications'.tr),
              const SizedBox(height: 8),
              Obx(() => _SwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'enable_prayer_notif'.tr,
                    subtitle: 'enable_prayer_notif_desc'.tr,
                    value: c.prayerEnabled.value,
                    onChanged: c.setPrayerEnabled,
                  )),
              const SizedBox(height: 8),
              Obx(() => _SwitchTile(
                    icon: Icons.history_toggle_off_outlined,
                    title: 'enable_post_prayer'.tr,
                    subtitle: 'enable_post_prayer_desc'.tr,
                    value: c.postEnabled.value,
                    onChanged: c.setPostEnabled,
                  )),
              const SizedBox(height: 8),
              Obx(() => _SwitchTile(
                    icon: Icons.upcoming_outlined,
                    title: 'enable_upcoming'.tr,
                    subtitle: 'enable_upcoming_desc'.tr,
                    value: c.upcomingEnabled.value,
                    onChanged: c.setUpcomingEnabled,
                  )),

              const SizedBox(height: 24),
              _Header('notification_sounds'.tr),
              const SizedBox(height: 8),
              _SoundGroup(
                icon: Icons.volume_up_outlined,
                title: 'prayer_sound'.tr,
                options: NotificationSounds.prayer,
                selectedId: c.prayerSoundId,
                onSelect: c.setPrayerSound,
              ),
              const SizedBox(height: 8),
              _SoundGroup(
                icon: Icons.notifications_none_outlined,
                title: 'reminder_sound'.tr,
                options: NotificationSounds.reminder,
                selectedId: c.reminderSoundId,
                onSelect: c.setReminderSound,
              ),

              const SizedBox(height: 24),
              _ActionTile(
                icon: Icons.send_outlined,
                title: 'test_notification'.tr,
                color: colors.primary,
                onTap: c.sendTest,
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.open_in_new,
                title: 'open_notif_settings'.tr,
                color: colors.onSurfaceVariant,
                onTap: c.openSystemSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _SoundGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<NotificationSound> options;
  final RxString selectedId;
  final ValueChanged<String> onSelect;

  const _SoundGroup({
    required this.icon,
    required this.title,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: colors.primary, size: 22),
              const SizedBox(width: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Obx(() => RadioGroup<String>(
                  groupValue: selectedId.value,
                  onChanged: (v) => onSelect(v!),
                  child: Column(
                    children: [
                      for (final s in options)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: s.id,
                          title: Text(s.labelKey.tr,
                              style: const TextStyle(fontSize: 14)),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(title,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}

class _DisabledBanner extends StatelessWidget {
  final VoidCallback onOpen;
  const _DisabledBanner({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.notifications_off_outlined, color: colors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('notif_disabled_title'.tr,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: colors.error)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('notif_disabled_msg'.tr,
              style: TextStyle(fontSize: 13, color: colors.onSurface)),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton(
              onPressed: onOpen,
              child: Text('notif_enable_cta'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

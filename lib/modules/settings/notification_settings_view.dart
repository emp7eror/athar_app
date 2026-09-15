import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/notification_sounds.dart';
import '../../core/services/notification_service.dart';
import '../../core/ui/athar_ui.dart';
import 'notification_settings_controller.dart';

/// Which prayer reminders are on, which sounds they use, and a way to test
/// them.
class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(NotificationSettingsController());

    return Scaffold(
      appBar: AtharAppBar(title: 'notification_settings'.tr),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: c.refreshStatus,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AtharSpace.screen, AtharSpace.xs, AtharSpace.screen, AtharSpace.xxl),
            children: [
              Obx(
                () => c.status.value == NotifStatus.ready
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: AtharSpace.lg),
                        child: _DisabledBanner(onOpen: c.openSystemSettings),
                      ),
              ),
              AtharListGroup(
                title: 'prayer_notifications'.tr,
                children: [
                  Obx(
                    () => _SwitchRow(
                      icon: Icons.notifications_active_rounded,
                      title: 'enable_prayer_notif'.tr,
                      subtitle: 'enable_prayer_notif_desc'.tr,
                      value: c.prayerEnabled.value,
                      onChanged: c.setPrayerEnabled,
                    ),
                  ),
                  Obx(
                    () => _SwitchRow(
                      icon: Icons.history_rounded,
                      title: 'enable_post_prayer'.tr,
                      subtitle: 'enable_post_prayer_desc'.tr,
                      value: c.postEnabled.value,
                      onChanged: c.setPostEnabled,
                    ),
                  ),
                  Obx(
                    () => _SwitchRow(
                      icon: Icons.upcoming_rounded,
                      title: 'enable_upcoming'.tr,
                      subtitle: 'enable_upcoming_desc'.tr,
                      value: c.upcomingEnabled.value,
                      onChanged: c.setUpcomingEnabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AtharSpace.lg),
              AtharSectionHeader(title: 'notification_sounds'.tr),
              _SoundGroup(
                icon: Icons.volume_up_rounded,
                title: 'prayer_sound'.tr,
                options: NotificationSounds.prayer,
                selectedId: c.prayerSoundId,
                onSelect: c.setPrayerSound,
              ),
              const SizedBox(height: AtharSpace.sm),
              _SoundGroup(
                icon: Icons.notifications_rounded,
                title: 'reminder_sound'.tr,
                options: NotificationSounds.reminder,
                selectedId: c.reminderSoundId,
                onSelect: c.setReminderSound,
              ),
              const SizedBox(height: AtharSpace.lg),
              AtharListGroup(
                children: [
                  AtharListRow(
                    icon: Icons.send_rounded,
                    title: 'test_notification'.tr,
                    showChevron: false,
                    onTap: c.sendTest,
                  ),
                  AtharListRow(
                    icon: Icons.open_in_new_rounded,
                    tone: AtharTone.neutral,
                    title: 'open_notif_settings'.tr,
                    onTap: c.openSystemSettings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AtharListRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showChevron: false,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// One sound choice per notification kind.
class _SoundGroup extends StatelessWidget {
  const _SoundGroup({
    required this.icon,
    required this.title,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final IconData icon;
  final String title;
  final List<NotificationSound> options;
  final RxString selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return AtharCard(
      padding: const EdgeInsets.fromLTRB(AtharSpace.md, AtharSpace.md, AtharSpace.md, AtharSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AtharSize.icon, color: context.colors.primary),
              const SizedBox(width: AtharSpace.sm),
              Expanded(child: Text(title, style: context.type.cardTitle)),
            ],
          ),
          Obx(
            () => RadioGroup<String>(
              groupValue: selectedId.value,
              onChanged: (v) => onSelect(v!),
              child: Column(
                children: [
                  for (final s in options)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: s.id,
                      title: Text(s.labelKey.tr, style: context.text.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifications are off at the system level — nothing Athar schedules will
/// arrive until that changes.
class _DisabledBanner extends StatelessWidget {
  const _DisabledBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final error = context.colors.error;

    return Container(
      padding: const EdgeInsets.all(AtharSpace.md),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AtharRadius.card),
        border: Border.all(color: error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_off_rounded, color: error, size: AtharSize.icon),
              const SizedBox(width: AtharSpace.sm),
              Expanded(
                child: Text(
                  'notif_disabled_title'.tr,
                  style: context.type.cardTitle.copyWith(color: error),
                ),
              ),
            ],
          ),
          const SizedBox(height: AtharSpace.xs),
          Text('notif_disabled_msg'.tr, style: context.text.bodySmall),
          const SizedBox(height: AtharSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AtharButton(label: 'notif_enable_cta'.tr, compact: true, onPressed: onOpen),
          ),
        ],
      ),
    );
  }
}

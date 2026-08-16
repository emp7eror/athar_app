/// Catalogue of user-selectable notification sounds.
///
/// The audio files are shipped as native resources (see
/// `assets/audio/README.md`). Each option carries:
/// - [id]         : the value we persist in storage.
/// - [androidRaw] : the bare `res/raw` resource name (no extension) used by
///                  [RawResourceAndroidNotificationSound].
/// - [iosFile]    : the bundled filename used by `DarwinNotificationDetails`.
/// - [labelKey]   : localization key for the human-readable name.
class NotificationSound {
  final String id;
  final String androidRaw;
  final String iosFile;
  final String labelKey;

  const NotificationSound({
    required this.id,
    required this.androidRaw,
    required this.iosFile,
    required this.labelKey,
  });
}

abstract final class NotificationSounds {
  /// Sounds offered for the *prayer-time* notification.
  static const prayer = <NotificationSound>[
    NotificationSound(
      id: 'athan1',
      androidRaw: 'athan1',
      iosFile: 'athan1.mp3',
      labelKey: 'sound_athan1',
    ),
    NotificationSound(
      id: 'athan2',
      androidRaw: 'athan2',
      iosFile: 'athan2.mp3',
      labelKey: 'sound_athan2',
    ),
    NotificationSound(
      id: 'athan3',
      androidRaw: 'athan3',
      iosFile: 'athan3.mp3',
      labelKey: 'sound_athan3',
    ),
  ];

  /// Sounds offered for the *reminder* notifications (post-prayer + upcoming).
  static const reminder = <NotificationSound>[
    NotificationSound(
      id: 'athan_reminder_1',
      androidRaw: 'athan_reminder_1',
      iosFile: 'athan_reminder_1.mp3',
      labelKey: 'sound_reminder1',
    ),
    NotificationSound(
      id: 'athan_reminder_2',
      androidRaw: 'athan_reminder_2',
      iosFile: 'athan_reminder_2.mp3',
      labelKey: 'sound_reminder2',
    ),
  ];

  static const defaultPrayerId = 'athan1';
  static const defaultReminderId = 'athan_reminder_1';

  static NotificationSound prayerById(String? id) => prayer.firstWhere(
        (s) => s.id == id,
        orElse: () => prayer.first,
      );

  static NotificationSound reminderById(String? id) => reminder.firstWhere(
        (s) => s.id == id,
        orElse: () => reminder.first,
      );

  /// Every sound (used when pre-creating one Android channel per sound).
  static List<NotificationSound> get all => [...prayer, ...reminder];
}

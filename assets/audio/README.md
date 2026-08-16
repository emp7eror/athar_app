# Audio assets

Drop the following files here (added later):

- `athan1.mp3`, `athan2.mp3`, `athan3.mp3` — prayer-time notification sounds
- `athan_reminder_1.mp3`, `athan_reminder_2.mp3` — reminder notification sounds
- `done.mp3` — played in-app when a prayer is marked complete

## Notification sounds (important)

`flutter_local_notifications` does **not** play sounds from the Flutter `assets/`
bundle. For the notification sounds to work at the OS level the same files must
also be placed as native resources:

- **Android:** copy each file (lowercase, no spaces) into
  `android/app/src/main/res/raw/` e.g. `res/raw/athan1.mp3`. Referenced by
  bare name (`athan1`) via `RawResourceAndroidNotificationSound`.
- **iOS:** add each file to the Runner target in Xcode (e.g. `athan1.mp3`).
  Referenced by full filename via `DarwinNotificationDetails(sound: 'athan1.mp3')`.

`done.mp3` only needs to live in this `assets/audio/` folder — it is played
in-app through `audioplayers`, not through the notification system.

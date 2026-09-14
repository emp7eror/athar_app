# Athar — iOS Deployment Guide

Everything needed to build, test and ship the Athar Flutter app to the App Store
with **push notifications, scheduled Adhan notifications and every feature working**.

- Bundle ID: `com.empire.tech.athar.athar`
- Firebase project: `athar-30fad` (iOS app `1:686705336396:ios:16b37e048156307f1d94e9`)
- Minimum iOS: **15.0** (required by `firebase_core` 4.x / `firebase_messaging` 16.x)
- API: `https://athar.ferasmelhem.com/api`

---

## 0. What is already configured in this repo

| File | What it does |
|---|---|
| `ios/Podfile` | iOS 15 platform; enables `PERMISSION_NOTIFICATIONS=1` for `permission_handler` (without it iOS always reports notifications as **denied** and the permission gate never passes). |
| `ios/Runner/Runner.entitlements` | Push Notifications capability (`aps-environment`). Wired to all Runner build configs via `CODE_SIGN_ENTITLEMENTS`. |
| `ios/Runner/Info.plist` | Location, Photo Library, Camera and **Motion** usage texts (Motion is required by `sensors_plus` for Dhikr shake-to-count — without it the app crashes when the sensor starts); `UIBackgroundModes → remote-notification`; `CFBundleLocalizations` (ar, en); `ITSAppUsesNonExemptEncryption = false` (skips the export-compliance question — the app only uses HTTPS). |
| `ios/Runner/AppDelegate.swift` | Sets the `UNUserNotificationCenter` delegate (foreground notifications + taps/actions), registers the plugin callback for background notification actions, registers for remote notifications (APNs). |
| `ios/Runner.xcodeproj/project.pbxproj` | Deployment target 15.0; entitlements; Arabic region; **"Bundle Notification Sounds"** build phase (see §6). |
| `ios/Flutter/Debug.xcconfig`, `Release.xcconfig` | Include the CocoaPods xcconfigs. |
| `lib/core/constants/notification_sounds.dart` | iOS sound names now `.caf`. |
| `lib/modules/auth/auth_controller.dart` | Waits for the APNs token before requesting the FCM token (avoids `apns-token-not-set`). |
| `lib/core/services/notification_service.dart` | Sends refreshed FCM tokens to the server (`onTokenRefresh`). |
| `lib/core/services/prayer_notification_scheduler.dart` | Schedules 4 days ahead on iOS (60 notifications) — iOS keeps only 64 pending local notifications. |

---

## 1. Requirements

- A **Mac** with the latest **Xcode** accepted by App Store Connect (check Apple's current SDK requirement before submitting).
- **CocoaPods** — `sudo gem install cocoapods` or `brew install cocoapods`.
- **Flutter 3.47** (the version this project is on) — `flutter doctor` must show iOS toolchain ✓.
- An **Apple Developer Program** membership (paid) with the Account Holder / Admin role.
- Access to the **Firebase console** for project `athar-30fad`.
- A **real iPhone** for testing push (see §5).

---

## 2. Apple Developer portal (one-time)

1. **Certificates, Identifiers & Profiles → Identifiers → +**
   - App ID, Bundle ID (explicit): `com.empire.tech.athar.athar`
   - Capabilities: tick **Push Notifications**.
2. **Keys → +** → name it "Athar APNs", tick **Apple Push Notifications service (APNs)** → Continue → Register.
   - **Download the `.p8` file** (it can only be downloaded once — store it safely).
   - Note the **Key ID** and your **Team ID** (top-right of the portal / Membership page).
3. Signing certificates and provisioning profiles can be left to Xcode (**Automatically manage signing**).

---

## 3. Firebase console (one-time)

1. Project settings → **Your apps** → confirm the iOS app with bundle ID
   `com.empire.tech.athar.athar` exists (it does: `firebase_options.dart` already contains its config).
2. Project settings → **Cloud Messaging** → **Apple app configuration** →
   **APNs Authentication Key → Upload**: the `.p8` file, Key ID and Team ID from §2.
   - One `.p8` key works for both development and production — no certificates needed.
3. `GoogleService-Info.plist` is **not required**: Firebase is initialised from
   `lib/firebase_options.dart`. (If you later add Crashlytics/Analytics, run
   `flutterfire configure` to regenerate both.)

> Without step 3.2, the app gets an FCM token but **no push ever arrives on iOS**.

---

## 4. First build on the Mac

```bash
git pull
flutter clean
flutter pub get
cd ios
pod install --repo-update
cd ..
open ios/Runner.xcworkspace        # always the .xcworkspace, never .xcodeproj
```

In Xcode → **Runner** target → **Signing & Capabilities**:

1. **Team**: select your team. Keep *Automatically manage signing* on.
2. Confirm these capabilities are listed (they come from the entitlements/Info.plist; add them with **+ Capability** if Xcode doesn't show them):
   - **Push Notifications**
   - **Background Modes** → ✅ *Remote notifications*
3. **General → Minimum Deployments**: iOS 15.0.
4. **Build Phases**: confirm **Bundle Notification Sounds** runs after *Copy Bundle Resources*.

Run on a device:

```bash
flutter run --release -d <your-iphone-id>    # `flutter devices` lists ids
```

---

## 5. Test checklist (real iPhone)

Push notifications do not work reliably on the Simulator — use a device.

**Onboarding & permissions**
- [ ] Permission gate asks for **location** → prayer times match your city.
- [ ] Permission gate asks for **notifications** → iOS dialog appears and the gate advances after *Allow*.
- [ ] Deny notifications → gate shows the "open Settings" path; enabling in Settings is picked up on return.

**Local (scheduled) notifications**
- [ ] Settings → Notifications → **Test notification** shows and plays the selected **Adhan sound** (not the default ding).
- [ ] Change prayer sound / reminder sound → test again → new sound plays.
- [ ] Prayer-time, "20 min before" and "30 min after" notifications fire at the right times with the app closed.
- [ ] Toggling each notification type off stops it.

**Push (FCM)**
- [ ] Log in → server stores an FCM token for the user (check `users.fcm_token` or backend logs).
- [ ] Friend **nudge** arrives with the app in **background**, **terminated** and **foreground**.
- [ ] Long-press the nudge → *Yes I prayed / I'll pray soon / I won't pray* buttons appear (see Known gaps).
- [ ] Friend **level-up / Quran reward / khatma** push → tapping opens that friend's profile (background and cold start).

**Other features**
- [ ] Home: prayer checklist, marking prayers, points, level-up popup, done sound.
- [ ] Profile → change avatar (Photo Library prompt appears; picking works).
- [ ] Friends → copy / share code (share sheet on iPhone **and iPad**).
- [ ] Quran reader: pages load, daily reward, khatma popup; Dhikr counter.
- [ ] Leaderboard, Stats, Coach (AI), Legal pages, language switch (AR/EN, RTL), dark mode.
- [ ] Offline: airplane mode → prayer times still show; notice appears.

---

## 6. Notification sounds on iOS

iOS **cannot use `.mp3` as a notification sound**. It needs `.caf` / `.aiff` / `.wav`,
**≤ 30 seconds**, inside the app bundle — otherwise it silently plays the default sound.

This is automated: the **Bundle Notification Sounds** build phase converts every
`android/app/src/main/res/raw/*.mp3` into `<name>.caf` with Apple's `afconvert`
at build time, so both platforms share one set of files.

Current durations (all under the limit): `athan1` 18s, `athan2` 15s, `athan3` 12s,
`athan_reminder_1` 14s, `athan_reminder_2` 23s.

**Adding a new sound:** put `name.mp3` (≤ 30s) in `android/app/src/main/res/raw/`
and add an entry in `lib/core/constants/notification_sounds.dart` with
`iosFile: 'name.caf'`.

To verify a build contains them:
`unzip -l build/ios/ipa/*.ipa | grep .caf`

---

## 7. iOS behaviour differences (by design)

- **64 pending notifications max.** iOS drops anything beyond the 64 soonest, so the
  scheduler lays out **4 days** on iOS (60 notifications) vs 7 on Android. It tops
  the schedule back up **every time the app is opened/resumed** — a user who doesn't
  open the app for more than 4 days stops receiving prayer notifications until they do.
- **No background execution.** iOS doesn't run Dart on a timer; `workmanager` is a
  dependency but isn't used. All prayer notifications are pre-scheduled local notifications.
- **Exact timing** needs no special permission on iOS (Android's exact-alarm request is skipped).
- **Foreground pushes** are re-posted by the app as local notifications
  (`NotificationService._bindForegroundMessages`), so they show while the app is open.

---

## 8. Backend (Laravel) — already compatible

`app/Services/FcmService.php` sends FCM HTTP v1 messages with an `apns` block
(`apns-priority: 10`, `aps.sound: default`, `aps.category` = `ATHAR_NUDGE` for nudges),
which matches the iOS notification category registered by the app. Nothing to change,
as long as the server has:

- `FCM_PROJECT_ID=athar-30fad` (or `services.fcm.project_id`)
- `services.fcm.credentials` → path to the Firebase **service-account JSON**

---

## 9. Release build & upload

1. Bump the version in `pubspec.yaml` — `version: 1.0.5+5` (name + build number;
   the build number must increase for every upload).
2. Build:
   ```bash
   flutter build ipa --release
   ```
   Output: `build/ios/ipa/*.ipa` and `build/ios/archive/Runner.xcarchive`.
3. Upload — either:
   - `open build/ios/archive/Runner.xcarchive` → Xcode Organizer → **Distribute App → App Store Connect**, or
   - Apple **Transporter** app → drag the `.ipa`.
4. App Store Connect → **TestFlight** → add internal testers → run §5 again on the TestFlight build
   (this is the first time push runs against the **production** APNs environment).

---

## 10. App Store Connect listing

Create the app: **My Apps → + → New App** → platform iOS, bundle ID
`com.empire.tech.athar.athar`, SKU e.g. `athar-ios`, primary language Arabic.

- **Name** (≤ 30 chars) and **Subtitle**, in Arabic and English localizations.
- **Screenshots**: 6.9" iPhone required. The app currently supports **iPad**
  (`TARGETED_DEVICE_FAMILY = 1,2`), so **13" iPad screenshots are also required** —
  or make it iPhone-only in Xcode (General → Supported Destinations) if you don't want to ship on iPad.
- **Privacy Policy URL**: required (the app already has a privacy page — use its public URL).
- **Support URL**.
- **Category**: Lifestyle (or Reference). **Age rating** questionnaire.
- **App Privacy** ("nutrition label") — declare what the app collects:
  - *Contact info*: Name, Email (account) — linked to user.
  - *Location*: Precise/coarse location (sent to the API for prayer times) — linked to user.
  - *User content*: Photos (avatar), prayer notes/mood — linked to user.
  - *Identifiers*: Device ID (guest login), push token — linked to user.
  - *Usage data*: prayer/Quran/dhikr activity, points — linked to user.
  - Not used for tracking/ads (unless you add analytics later).
- **App Review notes**: give a demo account (email/password) or explain *Continue as guest*;
  mention location is used only for prayer times and notifications for prayer reminders.

After the first approval, put the numeric App Store id in
`lib/core/utils/store_link.dart` (`_iosAppStoreId`) so **Settings → App version**
opens the App Store listing. (`upgrader` finds the listing by bundle ID on its own.)

---

## 11. ⚠️ Must fix before submitting

1. **In-app account deletion is missing.** App Store Guideline 5.1.1(v) requires any app
   that lets users create an account to let them **delete the account from inside the app**.
   Neither the app nor the API (`routes/api.php`) has this today → expect a rejection.
   Needed: an API endpoint that deletes/anonymises the user and their data, and a
   "Delete account" action (with confirmation) in Profile or Settings.
2. **App Store icon is invalid.** `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
   is **512×512 and has transparency**. App Store Connect requires **1024×1024, no alpha**.
   Export a real 1024×1024 opaque PNG from the source artwork and regenerate the icon set
   (e.g. with `flutter_launcher_icons` and `remove_alpha_ios: true`).
3. **Display name.** `CFBundleDisplayName` in `ios/Runner/Info.plist` is currently
   `Athar - أثر`. Update it if the app name should be *Athar Al Omor | أَثَرُ العُمُر*
   (keep it short — long names get truncated under the icon).

---

## 12. Known gaps (not iOS-specific)

- **Nudge action buttons** (*Yes I prayed / I'll pray soon / I won't pray*) render on both
  platforms, but `NotificationService._onAction` only handles profile-opening payloads —
  pressing an action button currently does nothing beyond opening the app.
- **Permission prompt language.** iOS system prompts use the `Info.plist` texts (English).
  For Arabic prompts, add `ar.lproj/InfoPlist.strings` in Xcode (File → New → Strings File,
  localize for Arabic) with `NSLocationWhenInUseUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSCameraUsageDescription` translated.

---

## 13. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `pod install` fails: *requires a higher minimum deployment target* | Podfile/Xcode must be iOS 15 — already set; run `pod repo update` and retry. |
| `CocoaPods could not find compatible versions` | `cd ios && rm -rf Pods Podfile.lock && pod install --repo-update`. |
| Notification permission always **denied**, no dialog | `PERMISSION_NOTIFICATIONS=1` missing → re-run `pod install` with this Podfile, clean build. |
| `[firebase_messaging/apns-token-not-set]` | Push capability / provisioning profile missing push, or running on Simulator. Check §4 capabilities. |
| Token received but **no push arrives** | APNs key not uploaded to Firebase (§3.2), or wrong Team ID / Key ID. |
| Pushes work in TestFlight but not debug (or reverse) | Using APNs **certificates** instead of the `.p8` key — switch to the key. |
| Notification plays the **default sound** | `.caf` missing from bundle — check the *Bundle Notification Sounds* phase ran; file must be ≤ 30s. |
| Notifications don't show while app is open | `AppDelegate` delegate line removed — restore `UNUserNotificationCenter.current().delegate = self`. |
| Crash when picking an avatar | `NSPhotoLibraryUsageDescription` missing from Info.plist. |
| Upload rejected: *Missing Info.plist value* / *Invalid icon* | See §11.2; ensure all usage strings exist. |

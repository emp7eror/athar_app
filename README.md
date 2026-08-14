# Athar — Flutter App (أثر)

Offline-first, bilingual (Arabic / English) prayer habit-tracker. Built with
**GetX** for state, routing, dependency injection, and localization. Prayer
times are computed **on-device** (no network needed to know when to pray);
points, levels, streaks, friends, stats, and push come from the Athar Laravel
API.

---

## Requirements

- Flutter **3.19+** (Dart 3)
- Android `minSdk` **21+** (required by `flutter_local_notifications` and
  Firebase)
- A running Athar API (see the backend README)
- A Firebase project (for push / friend nudges)

---

## Quick start

This repo is a source tree meant to drop over a fresh Flutter project, so you
get the Android/iOS runners and Gradle scaffolding.

```bash
cd athar
flutter pub get
flutter run
```

Set the API base URL first (see Configuration) or the app will launch but every
request will fail with a Dio connection error.

---

## Configuration

### 1. API base URL — required

`lib/core/constants/api_endpoints.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

- **Android emulator:** `http://10.0.2.2:8000/api` (`10.0.2.2` is the emulator's
  alias for the host machine's `localhost`) — this is the default.
- **iOS simulator:** `http://localhost:8000/api`
- **Physical device:** your machine's LAN IP, e.g. `http://192.168.1.20:8000/api`
  (device and computer on the same network).

A wrong base URL surfaces as a runtime connection error, not a build failure, so
it's easy to miss.

### 2. Android build — core library desugaring — required

`flutter_local_notifications` needs Java 8 API desugaring. In
`android/app/build.gradle(.kts)`, inside `android { }`:

```groovy
compileOptions {
    coreLibraryDesugaringEnabled true          // Kotlin DSL: isCoreLibraryDesugaringEnabled = true
    sourceCompatibility JavaVersion.VERSION_1_8
    targetCompatibility JavaVersion.VERSION_1_8
}
```

and add the dependency:

```groovy
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

Bump the desugar version if AGP asks for a higher minimum.

### 3. Notifications permission — required for Android 13+

In `android/app/src/main/AndroidManifest.xml`, above `<application>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

The runtime prompt is requested from `NotificationService.init()`.

### 4. Firebase / push — required for nudges & friend broadcasts

```bash
dart pub global activate flutterfire_cli
flutterfire configure     # writes lib/firebase_options.dart + google-services.json
```

Add the Google Services Gradle plugin:

- `android/settings.gradle(.kts)` plugins block:
  `id "com.google.gms.google-services" version "4.4.2" apply false`
- `android/app/build.gradle(.kts)` plugins block:
  `id "com.google.gms.google-services"`

`main()` initializes Firebase and registers the background handler; after login,
`AuthController` fetches the FCM token and posts it to `/auth/fcm-token`. Without
`flutterfire configure`, the app still builds and runs — it just won't receive
push.

### 5. Location — optional

There is **no `geolocator` dependency**, so no location permissions are needed.
`AdhanService` falls back to Makkah coordinates (`21.4225, 39.8262`) until the
user sets a location, at which point `LocationService` persists it and syncs to
`/user/location`. Add `geolocator` if you want automatic device location.

### 6. Background streak reminders — optional

`workmanager` is in `pubspec.yaml` but intentionally **not initialized** — the
authoritative streak logic is the server's nightly 23:59 job. Wire
`Workmanager().initialize(...)` in `main()` only if you want an on-device
reminder nudge.

### 7. RTL font — optional polish

The theme references a `Cairo` font family. Add the font files under
`pubspec.yaml` `fonts:` for fully polished Arabic rendering; without it, the app
falls back to the platform default (still RTL-correct).

---

## How it works

**Prayer times (offline).** `AdhanService` uses the `adhan` package with
`CalculationMethod.egyptian` and `Madhab.shafi`, from the user's stored
coordinates. It computes the active window (current prayer start → next prayer
start; Fajr until sunrise) and the next prayer for the home-screen countdown. No
network is required to know prayer times.

**Marking a prayer.** The home checklist enables a prayer only inside its window
(client-side gate). Marking posts to `/prayers/mark`; the server applies points
and returns updated totals. The backend adds its own date guard as
defense-in-depth.

**State & DI.** `InitialBinding` registers the permanent services
(`StorageProvider`, `LocalizationController`, `DioClient`, `ApiProvider`,
`AdhanService`, `LocationService`) and async-inits `NotificationService`. Each
feature module has its own controller + binding.

**Networking.** A single `DioClient` with an interceptor that injects the
Sanctum `Authorization: Bearer` token and the `Accept-Language` header, and
clears the session + redirects to `/auth` on a 401. All calls go through the
typed `ApiProvider`.

**Localization & RTL.** `LocalizationController` persists the chosen language and
swaps `ar` / `en` instantly via `Get.updateLocale`, flipping the layout
direction. Strings live in `AppTranslations`; the server sends localized content
based on the `Accept-Language` header the interceptor attaches.

**Session.** `StorageProvider` (GetStorage) holds the token, cached user, and
coordinates. `main()` picks the initial route: `/home` if logged in, else
`/auth`.

---

## Project structure

```
lib/
  main.dart                          # entrypoint: Firebase init, GetMaterialApp, routing
  core/
    bindings/initial_binding.dart    # registers permanent services
    constants/                       # api_endpoints, app_colors, level_thresholds
    localization/                    # app_translations, localization_controller
    network/                         # dio_client, api_interceptors
    services/                        # adhan, location, notification
  data/
    models/                          # user, prayer_log, friend, leaderboard
    providers/                       # api_provider (typed API), storage_provider
  modules/
    auth/                            # login / register
    home/                            # checklist, next-prayer countdown, quote
    friends/                         # add by code, pending requests, nudge
    leaderboard/                     # points / streak tabs
    stats/                           # daily %, weekly chart, per-prayer averages
    shell/                           # bottom-nav host (Home/Friends/Leaderboard/Stats)
```

---

## Key dependencies

`get` · `get_storage` · `dio` · `adhan` · `intl` · `fl_chart` ·
`flutter_local_notifications` · `workmanager` · `firebase_core` ·
`firebase_messaging`

---

## Build

```bash
flutter clean
flutter pub get
flutter run                       # debug
flutter build apk --release       # Android release
flutter build appbundle --release # Play Store
```

If the Android build fails on `checkDebugAarMetadata` mentioning desugaring, see
Configuration §2. If it fails on `minSdk`, raise it to 21+ in
`android/app/build.gradle` `defaultConfig`.

---

## License

Proprietary — all rights reserved.

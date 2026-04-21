# Firebase Auth Setup and E2E

This app now uses Firebase Authentication for identity:

- Google sign-in on Android and iOS.
- Apple sign-in on iOS only.
- Persistent auth session across app relaunch.

## 1) Firebase Console Setup

1. Create a Firebase project.
2. Add Android app `com.aunCreations.aun_reqstudio`.
3. Add iOS app bundle ID matching your Runner target.
4. Enable providers:
   - Google (Android + iOS).
   - Apple (iOS).
5. Download and add:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

## 2) Android Setup Checklist

1. Add SHA-1 and SHA-256 fingerprints in Firebase Android app settings.
2. Verify Gradle plugin is applied:
   - `com.google.gms.google-services` in Android plugin management.
   - `id("com.google.gms.google-services")` in `android/app/build.gradle.kts`.
3. Rebuild app after adding `google-services.json`.

## 3) iOS Setup Checklist

1. In Xcode Runner target, enable capability:
   - Sign In with Apple
2. Replace `REVERSED_CLIENT_ID` in `ios/Runner/Info.plist` with actual value from `GoogleService-Info.plist`.
3. Verify Apple Team, Bundle ID, and provisioning profiles are valid.
4. Build once from Xcode or full `flutter run` (hot restart cannot load new native plugins/capabilities).

## 4) Session and Security Behavior

- Firebase user session is persisted by SDK across relaunch.
- App derives backend session artifact from Firebase identity and stores it in secure storage.
- Backend session artifacts use `flutter_secure_storage`, never Hive.
- Logout clears backend session artifacts, signs out Firebase provider(s), and invalidates user-scoped providers.

## 5) iCloud Backup and Restore Policy

- Treat restored local session artifacts as untrusted until server-validated.
- Firebase sessions may become invalid after restore/reinstall; app must revalidate at launch.
- Backup/restore must not bypass authentication checks.

## 6) E2E Validation Checklist

- Google sign-in works on Android.
- Google sign-in works on iOS.
- Apple sign-in works on iOS.
- Account linking works for same user identity across Google and Apple.
- Cold relaunch keeps signed-in user in authenticated routes.
- Sign-out returns user to auth route and blocks protected routes.
- Offline logout still clears local secure session artifacts immediately.
- Post-restore/reinstall flow revalidates auth state before trusting local session artifacts.

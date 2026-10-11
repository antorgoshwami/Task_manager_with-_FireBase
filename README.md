# Firebase Task Manager

A Flutter task manager with email and Google sign in, per-user tasks in Cloud
Firestore, and Firebase Cloud Messaging notifications.

## Run on Android

1. Install the Flutter SDK and Android Studio, then connect an Android device
   or start an emulator.
2. From this directory, run:

   ```sh
   flutter pub get
   flutter run
   ```

The Android Firebase app configuration is in
`android/app/google-services.json`; shared Firebase options are in
`lib/firebase_options.dart`. Both currently point to the Firebase project
`fir-task-manager-94ad9`.

## Firebase services required at runtime

In that Firebase project, enable Email/Password sign in and create a Cloud
Firestore database. Firestore rules must let each signed-in user read and write
only `users/{uid}` and `users/{uid}/tasks/{taskId}` for their own UID. To use
Google sign in on Android, enable its provider and register the app's SHA-1 and
SHA-256 signing certificate fingerprints in Firebase; then download the
updated `google-services.json`.

Notifications need notification permission on the device. Firebase Cloud
Messaging token registration also writes to `users/{uid}` in Firestore.

## Other platforms

Firebase options are present for Android, iOS, macOS, web, and Windows. Local
notifications are enabled on Android, iOS, and macOS. Windows skips notification
initialization; Linux is not configured for Firebase in this project.

## Checks

```sh
flutter analyze
flutter test
flutter build apk --debug
```

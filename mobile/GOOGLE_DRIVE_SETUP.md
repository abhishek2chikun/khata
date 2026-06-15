# Google Drive Backup Setup

Google Drive backup uses the app's Android identity plus a Google web OAuth
client ID. Credentials must stay outside source control. The app supports both
official Android configuration paths:

- an untracked `mobile/android/app/google-services.json` that contains a web
  OAuth client entry; or
- `GOOGLE_DRIVE_SERVER_CLIENT_ID` supplied with `--dart-define`.

## Google Cloud configuration

1. Enable the Google Drive API in the selected Google Cloud project.
2. Configure the OAuth consent screen and add the intended Google account as a
   test user while the app remains in testing mode.
3. Create an Android OAuth client using the app's `applicationId` and the SHA-1
   fingerprint of the signing certificate used for that build.
4. Create a Web application OAuth client. Add it to `google-services.json` or
   use it as `GOOGLE_DRIVE_SERVER_CLIENT_ID` when building or running the app.

Print debug signing fingerprints with:

```sh
cd mobile/android
./gradlew signingReport
```

Run the local app with Drive enabled:

```sh
cd mobile
flutter run -d <device-id> \
  --dart-define=DATA_MODE=local \
  --dart-define=GOOGLE_DRIVE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Build a local release APK with the same configuration:

```sh
flutter build apk --release \
  --dart-define=DATA_MODE=local \
  --dart-define=GOOGLE_DRIVE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

The Android OAuth client must match the package name and signing certificate of
the installed APK. Debug and release signing certificates require separate
Android OAuth client registrations.

## Device verification

1. Open `Backup & Restore` and connect the Google account.
2. Set an encryption password of at least eight characters and retain it
   outside the device.
3. Run `Back up now` and verify a file appears in the visible `Khata Backups`
   Drive folder.
4. Relaunch the app and confirm the connected account and backup list return.
5. On disposable test data, restore the uploaded backup and verify invoices,
   customers, products, and balances match the pre-backup state.
6. Enable automatic backup and verify WorkManager catch-up after a missed 2:00
   a.m. run.

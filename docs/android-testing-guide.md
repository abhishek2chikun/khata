# Android Testing Guide

This guide covers both ways to test the Flutter app on Android:

- Android emulator on this Mac
- Physical Pixel over USB

The mobile app currently talks to `http://localhost:8000/` in `mobile/lib/main.dart`, so Android testing must forward port `8000` from the device back to your Mac.

## 1. One-Time Android Setup On macOS

I already installed these pieces on this Mac:

- `openjdk@17`
- `android-commandlinetools`
- Android SDK licenses
- Android SDK packages for platform tools, emulator, build tools, Android 35/36, and an ARM64 system image
- AVD: `Pixel_9_API_35`

If you need to repeat the setup on another Mac, run:

```bash
brew install openjdk@17
brew install --cask android-commandlinetools

export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

yes | sdkmanager --licenses
sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-35" \
  "platforms;android-36" \
  "build-tools;35.0.0" \
  "build-tools;28.0.3" \
  "system-images;android-35;google_apis;arm64-v8a"

avdmanager create avd \
  -n Pixel_9_API_35 \
  -k "system-images;android-35;google_apis;arm64-v8a" \
  -d pixel_9 \
  --force
```

For the current terminal, export the same variables before running Flutter Android commands:

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

If you want Flutter to remember the setup across shells, run:

```bash
flutter config --jdk-dir="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
flutter config --android-sdk="/opt/homebrew/share/android-commandlinetools"
```

Verify the toolchain:

```bash
flutter doctor -v
```

Expected result:

- `Flutter` is green
- `Android toolchain` is green

## 2. Start The Backend First

From the repo root, start PostgreSQL if needed:

```bash
docker start khata-postgres
```

If the container does not exist yet:

```bash
docker run --name khata-postgres \
  -e POSTGRES_USER=khata \
  -e POSTGRES_PASSWORD=khata \
  -e POSTGRES_DB=internal_billing \
  -p 55432:5432 \
  -d postgres:16
```

Set the backend database URL:

```bash
export BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing'
```

Run migrations:

```bash
(cd backend && BILLING_DATABASE_URL="$BILLING_DATABASE_URL" ../.venv/bin/python -m alembic upgrade head)
```

Create the first login user if needed:

```bash
BILLING_DATABASE_URL="$BILLING_DATABASE_URL" \
PYTHONPATH=backend \
.venv/bin/python -m app.commands.bootstrap_user \
  --username owner \
  --password secret123 \
  --display-name Owner
```

Start the backend server and leave it running:

```bash
BILLING_DATABASE_URL="$BILLING_DATABASE_URL" \
PYTHONPATH=backend \
.venv/bin/python -m uvicorn app.main:app --app-dir backend --reload
```

You should now have the API on `http://localhost:8010/`.

## 3. Install Flutter Dependencies

From the `mobile/` directory:

```bash
flutter pub get
```

## 4. Test With The Android Emulator

### 4.1 Start the emulator

On this machine, `flutter emulators` does not currently discover the Homebrew-installed emulator source cleanly, so use the emulator binary directly:

```bash
"/opt/homebrew/share/android-commandlinetools/emulator/emulator" -avd Pixel_9_API_35
```

Wait until the emulator finishes booting.

### 4.2 Confirm adb sees it

```bash
adb devices
```

Expected result: a device like `emulator-5554` shows as `device`.

### 4.3 Forward backend port 8010

If you want to use `localhost` inside Android, forward the port from the emulator back to your Mac:

```bash
adb reverse tcp:8010 tcp:8010
```

### 4.4 Run the Flutter app

From `mobile/`:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8010/
```

If your emulator ID differs, use the value from `adb devices` or `flutter devices`.

## 5. Test With A Physical Pixel

### 5.1 Enable developer mode on the phone

On the Pixel:

1. Open `Settings`.
2. Go to `About phone`.
3. Tap `Build number` seven times.
4. Go back to `System` -> `Developer options`.
5. Enable `USB debugging`.

### 5.2 Connect the phone

Connect the Pixel with a USB cable and accept the trust/debugging prompt on the device.

### 5.3 Confirm adb sees it

```bash
adb devices
```

Expected result: your phone serial appears as `device`.

If it shows `unauthorized`, unlock the phone and accept the USB debugging prompt.

### 5.4 Forward backend port 8010

```bash
adb reverse tcp:8010 tcp:8010
```

### 5.5 Run the Flutter app on the phone

From `mobile/`:

```bash
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:8010/
```

Replace `<device-id>` with your Pixel device ID.

## 6. First Manual Test Pass

Once the app opens, use this quick smoke test:

1. Log in with `owner` / `secret123`.
2. Open the inventory screen.
3. Add a product.
4. Edit the product.
5. Open sellers.
6. Create or inspect seller details.
7. Record a payment or balance adjustment if available.
8. Create an invoice and verify the preview flow.

If anything fails, capture:

- whether it happened on emulator or Pixel
- exact screen and button tapped
- expected result
- actual result
- backend terminal output
- `flutter run` output

## 7. Useful Commands While Debugging

Check connected Android devices:

```bash
adb devices
```

List Flutter-visible devices:

```bash
flutter devices
```

Re-run port forwarding:

```bash
adb reverse tcp:8000 tcp:8000
```

Remove port forwarding:

```bash
adb reverse --remove tcp:8000
```

Show connected emulators and phones with logs in the active `flutter run` session:

```bash
flutter run -d <device-id>
```

## 8. Common Problems

### `flutter doctor -v` shows Android toolchain errors

Re-export the environment variables:

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

### `adb devices` shows no device

- For emulator: wait until Android finishes booting.
- For Pixel: unlock the phone and approve USB debugging.
- Replug the cable and run `adb devices` again.

### Login or API calls fail on Android

Most likely cause: port forwarding was not applied.

Run:

```bash
adb reverse tcp:8000 tcp:8000
```

Then retry the request.

### Emulator starts but `flutter emulators` shows nothing

Use the direct emulator command from section 4.1. The AVD exists and can be launched directly even if `flutter emulators` does not list it.

## 9. Recommended Daily Flow

For day-to-day testing, this is the shortest reliable loop:

1. Start PostgreSQL.
2. Start the FastAPI backend.
3. Start the emulator or connect the Pixel.
4. Run `adb reverse tcp:8000 tcp:8000`.
5. Run `flutter run -d <device-id>` from `mobile/`.
6. Reproduce bugs and keep the backend and Flutter logs open.

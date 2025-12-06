# flutainer

Flutainer is a Flutter client for Portainer that lets you monitor and control
your Docker containers from mobile or desktop devices. It currently supports:

- Registering Portainer endpoints through API keys
- Browsing environments and their containers
- Filtering containers by name
- Starting, stopping, pausing, and unpausing containers with busy-state feedback
- Optional auto-refresh to keep statuses up to date

## Build & Run

1. Install Flutter (3.x or newer) plus the platform-specific toolchains (Android Studio, Xcode, etc.). Follow the official [installation guide](https://docs.flutter.dev/get-started/install).
2. Install project dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app on a connected device/emulator:
   ```sh
   flutter run
   ```
4. Build a release APK (adjust the target/platform command as needed):
   ```sh
   flutter build apk --release
   ```

## Continuous Integration & Releases

Automated builds run via the **Build Releases** workflow (`.github/workflows/build.yml`) on every push/PR to `main` and on `v*` tags:

- **Linux AppImage**: builds Flutter bundles on `x64` and `arm64` runners, then packages them via `scripts/ci/build_appimage.sh`. The resulting artifacts are `Flutainer-x64.AppImage` and `Flutainer-arm64.AppImage`.
- **Android split APKs**: produces one APK per ABI with `flutter build apk --split-per-abi`. When signing secrets are configured, APKs are release-signed.
- **Windows**: builds `flutter build windows --release` on `windows-latest` and publishes a zipped runner directory.

Download the artifacts from the Actions run summary to test or distribute nightly builds.

### Android signing secrets

Signing is handled automatically in CI when these GitHub Actions secrets are present:

| Secret | Description |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 of `upload-keystore.jks`. Generate with `base64 -w0 android/app/upload-keystore.jks`. |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password. |
| `ANDROID_KEY_ALIAS` | Entry alias used when generating the keystore. |
| `ANDROID_KEY_PASSWORD` | Key password. |

Create a keystore locally if you don't have one yet:

```sh
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -alias flutainerUpload -keyalg RSA -keysize 2048 -validity 10000
```

Configure `android/key.properties` with the same values for local builds (the file is ignored by Git). The CI job runs `scripts/ci/setup_android_signing.sh`, which re-creates `key.properties` and the keystore on the fly using the secrets above.

### Release helper scripts

- `scripts/ci/build_appimage.sh <x64|arm64>` packages an AppImage from the Flutter Linux bundle (used by CI but also handy locally).
- `scripts/android/build_play_bundle.sh` builds a release AAB after ensuring signing is configured.
- `scripts/android/build_fdroid_apks.sh` produces unsigned/signed split APKs for F-Droid submissions and lists their locations.

### Store deployments

#### Google Play (internal, beta, production)

1. Ensure `android/key.properties` references your release keystore.
2. Run `./scripts/android/build_play_bundle.sh` to generate `build/app/outputs/bundle/release/app-release.aab`.
3. Upload the `.aab` to the Google Play Console, fill release notes, and roll out to the desired track.
4. Tag the commit with `vX.Y.Z` to trigger CI so APK/AppImage artifacts are archived.

#### F-Droid

1. Run `./scripts/android/build_fdroid_apks.sh` to generate per-ABI APKs (arm64-v8a, armeabi-v7a, x86_64).
2. Copy the APKs plus their SHA256 hashes into your F-Droid metadata repository (e.g., `metadata/io.matteor.flutainer.txt`).
3. Update the metadata entry with the versionName/versionCode that match the APK manifests, then submit a merge request to the [F-Droid data repo](https://gitlab.com/fdroid/fdroiddata).
4. Once merged, F-Droid will reproduce the build using the same Flutter version listed in `pubspec.lock`.

## Roadmap

- [x] Review app permissions
- [x] Implement view container logs
- [x] Implement translations
- [x] Implement in-app logs (DEBUG only)
- [x] Apply a gracefully theme (with dark and light mode)
- [x] Apk signing
- [x] Github autobuild apk
- [ ] Publish to F-Droid
- [ ] Publish to PlayStore
- [ ] First stable release
- [ ] ... new ideas

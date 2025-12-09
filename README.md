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

TODO: the workflow does not exists yet!!

## Roadmap

- [x] Review app permissions
- [x] Implement view container logs
- [x] Implement translations
- [x] Implement in-app logs (DEBUG only)
- [x] Apply a gracefully theme (with dark and light mode)
- [x] Apk signing
- [ ] Github autobuild apk
- [ ] Publish to F-Droid
- [ ] Publish to PlayStore
- [ ] First stable release
- [ ] ... new ideas

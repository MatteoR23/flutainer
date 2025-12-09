# AGENTS

Quick guide for agents/assistants working on this repo.

## What is Flutainer
- Flutter client for Portainer (mobile + desktop).
- Register endpoints with API keys, browse environments/containers, start/stop/pause, view logs, optional auto-refresh.

## Stack & structure
- Flutter 3.x (Dart ^3.10.3) with Provider for state.
- MVVM layout: `lib/models`, `lib/viewmodels`, `lib/services`, `lib/views`.
- Key services: `PortainerService` for REST calls, `CredentialsStorage` (Secure/Memory) for credentials, `AppLogger` for debug logs.
- Localization generated in `lib/l10n`; use `context.l10n`/`AppLocalizations` for UI copy.

## Quick guidelines
- Follow lints in `analysis_options.yaml` (prefer const, avoid_print, use_key_in_widget_constructors, etc.).
- Never expose or log API keys; delegate persistence to `SecureCredentialsStorage`.
- Reuse `PortainerService` for HTTP calls and URL building.
- Handle loading/error states in UI and give feedback (e.g., snackbars).
- Keep light/dark theme support and existing translations; avoid hard-coded strings.
- If you touch logic, consider `flutter test`.

## Useful paths
- App bootstrap: `lib/main.dart`, `lib/viewmodels/app_view_model.dart`.
- Endpoints/Home: `lib/views/home_page_view.dart`.
- Containers list: `lib/views/list_containers_view.dart`.
- Container logs: `lib/views/container_log_view.dart`.
- Settings/theme/locale: `lib/views/settings_view.dart`, `lib/viewmodels/theme_view_model.dart`, `lib/viewmodels/locale_view_model.dart`.

## Working commands
- Install deps: `flutter pub get`.
- Tests: `flutter test`.
- Local run: `flutter run -d <device>`.
- Android release: `flutter build apk --release` (see scripts in `scripts/android`).
- Desktop/AppImage packaging scripts live in `scripts/ci`.

## Roadmap (from README)
- Publish to F-Droid and Play Store; prep the first stable release.

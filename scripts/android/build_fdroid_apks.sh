#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "android/key.properties" ]]; then
  echo "WARNING: android/key.properties not found. The resulting APKs will be unsigned." >&2
fi

flutter clean >/dev/null
flutter pub get
flutter build apk --release --split-per-abi

OUTPUT_DIR="build/app/outputs/flutter-apk"
echo "F-Droid APKs:"
ls "${OUTPUT_DIR}"/app-*-release.apk
echo "Remember to update your F-Droid metadata repo with checksums from these files."

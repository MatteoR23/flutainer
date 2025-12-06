#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "android/key.properties" ]]; then
  cat >&2 <<'EOF'
Missing android/key.properties.
Create one with your keystore credentials before building:
  storePassword=...
  keyPassword=...
  keyAlias=...
  storeFile=../app/upload-keystore.jks
EOF
  exit 1
fi

flutter clean >/dev/null
flutter pub get
flutter build appbundle --release

echo "Play Store bundle ready at build/app/outputs/bundle/release/app-release.aab"

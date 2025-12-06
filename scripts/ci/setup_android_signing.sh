#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  echo "ANDROID_KEYSTORE_BASE64 not set. Skipping signing setup (unsigned build)." >&2
  exit 0
fi

if [[ -z "${ANDROID_KEYSTORE_PASSWORD:-}" || -z "${ANDROID_KEY_PASSWORD:-}" || -z "${ANDROID_KEY_ALIAS:-}" ]]; then
  echo "Android signing secrets incomplete. Please set ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD, ANDROID_KEY_ALIAS." >&2
  exit 1
fi

KEYSTORE_PATH="android/app/upload-keystore.jks"
echo "${ANDROID_KEYSTORE_BASE64}" | base64 -d > "${KEYSTORE_PATH}"

cat > android/key.properties <<EOF
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=${KEYSTORE_PATH}
EOF

echo "Android signing key configured."

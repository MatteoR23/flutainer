#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-x64}"
BUNDLE_DIR="build/linux/${ARCH}/release/bundle"
if [[ ! -d "${BUNDLE_DIR}" ]]; then
  echo "Linux bundle not found at ${BUNDLE_DIR}. Run 'flutter build linux --release' first." >&2
  exit 1
fi

APPDIR="build/appimage/${ARCH}/AppDir"
OUTPUT_ROOT="build/appimage"
APP_NAME="Flutainer"

rm -rf "${APPDIR}"
mkdir -p "${APPDIR}/usr/bin"

cp -R "${BUNDLE_DIR}/." "${APPDIR}/usr/bin/"
chmod +x "${APPDIR}/usr/bin/flutainer"

cat >"${APPDIR}/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/flutainer" "$@"
EOF
chmod +x "${APPDIR}/AppRun"

cat >"${APPDIR}/flutainer.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Flutainer
Comment=Manage Portainer containers
Exec=flutainer
Icon=flutainer
Categories=Utility;Development;
EOF

mkdir -p "${APPDIR}/usr/share/icons/hicolor/512x512/apps"
cp assets/icons/app_icon.png "${APPDIR}/usr/share/icons/hicolor/512x512/apps/flutainer.png"
cp assets/icons/app_icon.png "${APPDIR}/flutainer.png"

case "${ARCH}" in
  x64)
    APPIMAGE_ARCH="x86_64"
    ;;
  arm64)
    APPIMAGE_ARCH="aarch64"
    ;;
  *)
    echo "Unsupported architecture '${ARCH}'" >&2
    exit 1
    ;;
esac

TOOLS_DIR="${OUTPUT_ROOT}/tools"
mkdir -p "${TOOLS_DIR}"
APPIMAGE_TOOL="${TOOLS_DIR}/appimagetool-${APPIMAGE_ARCH}.AppImage"

if [[ ! -f "${APPIMAGE_TOOL}" ]]; then
  curl -L "https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-${APPIMAGE_ARCH}.AppImage" \
    -o "${APPIMAGE_TOOL}"
  chmod +x "${APPIMAGE_TOOL}"
fi

OUTPUT="${OUTPUT_ROOT}/${APP_NAME}-${ARCH}.AppImage"
"${APPIMAGE_TOOL}" --appimage-extract-and-run "${APPDIR}" "${OUTPUT}"
chmod +x "${OUTPUT}"
echo "AppImage created at ${OUTPUT}"

#!/usr/bin/env bash
# Evrensel (arm64 + x86_64) .app uretir, ad-hoc imzalar ve zip'ler.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$SCRIPT_DIR/.."

# Surum: APP_VERSION > CHANGELOG.md'deki ilk "## [x.y.z]" basligi > 0.0.0
changelog_version() {
  sed -n 's/^## \[\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)\].*/\1/p' "$1" 2>/dev/null | head -n 1
}

EXE="TaskbarManagerForWirelessDevices"
APP_NAME="Taskbar Manager for Wireless Devices"
BUNDLE_ID="io.github.lburak58.TaskbarManagerForWirelessDevices"
VERSION="${APP_VERSION:-$(changelog_version "$REPO_ROOT/CHANGELOG.md")}"
VERSION="${VERSION:-0.0.0}"
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Gecersiz surum: '$VERSION' (beklenen x.y.z)" >&2
  exit 1
fi
echo "Surum: $VERSION"
DIST="dist"
APP="$DIST/$APP_NAME.app"
ZIP="$DIST/${EXE}-macOS.zip"

rm -rf "$DIST"
mkdir -p "$DIST"

if swift build -c release --arch arm64 --arch x86_64; then
  BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/$EXE"
else
  echo "Universal build basarisiz; iki ayri build + lipo deneniyor" >&2
  swift build -c release --arch arm64 --scratch-path .build-arm64
  swift build -c release --arch x86_64 --scratch-path .build-x86_64
  BIN="$DIST/$EXE-universal"
  lipo -create \
    "$(swift build -c release --arch arm64 --scratch-path .build-arm64 --show-bin-path)/$EXE" \
    "$(swift build -c release --arch x86_64 --scratch-path .build-x86_64 --show-bin-path)/$EXE" \
    -output "$BIN"
fi

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$EXE"
chmod +x "$APP/Contents/MacOS/$EXE"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>tr</string>
  <key>CFBundleExecutable</key><string>$EXE</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSBluetoothAlwaysUsageDescription</key><string>Bluetooth cihazlarının pil düzeyini göstermek için kullanılır.</string>
</dict>
</plist>
EOF

codesign --force --deep -s - "$APP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "Hazir: $ZIP"

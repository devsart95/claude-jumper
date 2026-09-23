#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Claude Jumper"
APP_DIR="$ROOT/dist/$APP_NAME.app"

# A stable identity keeps the Accessibility grant across rebuilds; ad-hoc ("-") asks again each build.
DEFAULT_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Apple Development/ { print $2; exit }')"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-${DEFAULT_IDENTITY:--}}"

cd "$ROOT"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT/.build/release/ClaudeJumper" "$APP_DIR/Contents/MacOS/ClaudeJumper"
cp "$ROOT/Assets/clawd-sunglasses.png" "$APP_DIR/Contents/Resources/clawd-sunglasses.png"
cp "$ROOT/Assets/ClaudeJumper.icns" "$APP_DIR/Contents/Resources/ClaudeJumper.icns"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Claude Jumper</string>
  <key>CFBundleDisplayName</key><string>Claude Jumper</string>
  <key>CFBundleIdentifier</key><string>py.devsar.claudejumper</string>
  <key>CFBundleExecutable</key><string>ClaudeJumper</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><false/>
  <key>CFBundleIconFile</key><string>ClaudeJumper</string>
  <key>NSInputMonitoringUsageDescription</key><string>Claude Jumper usa la barra espaciadora para saltar mientras trabajás en otras aplicaciones. No registra ni guarda el teclado.</string>
  <key>NSHumanReadableCopyright</key><string>© 2026 DevSar · Sprite: Icons8 (icons8.com)</string>
</dict>
</plist>
PLIST

codesign --force --deep --options runtime --sign "$SIGN_IDENTITY" "$APP_DIR"
echo "$APP_DIR (firmado con: $SIGN_IDENTITY)"

#!/bin/bash
# Build "DOMOVINA Browser.app" — bez Xcode-a, samo swiftc.
set -e
cd "$(dirname "$0")"

APP="DomovinaBrowser.app"
BIN="$APP/Contents/MacOS/DomovinaBrowser"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "Compiling…"
swiftc DomovinaBrowser.swift -o "$BIN" \
  -parse-as-library -O \
  -framework SwiftUI -framework WebKit -framework AppKit

# Branded app ikona (DOMOVINA mediakit glyph).
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>DomovinaBrowser</string>
  <key>CFBundleDisplayName</key>     <string>DOMOVINA Browser</string>
  <key>CFBundleExecutable</key>      <string>DomovinaBrowser</string>
  <key>CFBundleIconFile</key>        <string>AppIcon</string>
  <key>CFBundleIdentifier</key>      <string>link.domovina.browser</string>
  <key>CFBundleVersion</key>         <string>1</string>
  <key>CFBundleShortVersionString</key> <string>1.0</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>NSPrincipalClass</key>        <string>NSApplication</string>
  <key>NSHighResolutionCapable</key> <true/>
  <key>LSMinimumSystemVersion</key>  <string>14.0</string>
  <!-- Potrebno da macOS dopusti Bluetooth (cross-device passkey s telefona). -->
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>DOMOVINA Browser koristi Bluetooth za prijavu passkeyem s tvog telefona.</string>
</dict>
</plist>
PLIST

# Potpis. Za passkey/WebAuthn treba PRAVI Developer ID s odobrenim
# `com.apple.developer.web-browser` entitlementom — postavi ga preko:
#   SIGN_ID="Developer ID Application: Ime (TEAMID)" ./build.sh
# Bez toga je ad-hoc potpis (app radi, ali passkey za proizvoljne domene neće).
if [ -n "$SIGN_ID" ]; then
  echo "Signing s entitlementima ($SIGN_ID)…"
  codesign --force --options runtime \
    --entitlements DomovinaBrowser.entitlements \
    --sign "$SIGN_ID" "$APP"
else
  codesign --force --sign - "$APP" >/dev/null 2>&1 || true
fi

echo "Done → $APP"
echo "Pokreni s:  open \"$APP\""

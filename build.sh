#!/bin/bash
# Build "DOMOVINA Browser.app" — bez Xcode-a, samo swiftc.
set -e
cd "$(dirname "$0")"

APP="DomovinaBrowser.app"
BIN="$APP/Contents/MacOS/DomovinaBrowser"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

echo "Compiling…"
swiftc DomovinaBrowser.swift -o "$BIN" \
  -parse-as-library -O \
  -framework SwiftUI -framework WebKit -framework AppKit

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>DomovinaBrowser</string>
  <key>CFBundleDisplayName</key>     <string>DOMOVINA Browser</string>
  <key>CFBundleExecutable</key>      <string>DomovinaBrowser</string>
  <key>CFBundleIdentifier</key>      <string>link.domovina.browser</string>
  <key>CFBundleVersion</key>         <string>1</string>
  <key>CFBundleShortVersionString</key> <string>1.0</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>NSPrincipalClass</key>        <string>NSApplication</string>
  <key>NSHighResolutionCapable</key> <true/>
  <key>LSMinimumSystemVersion</key>  <string>14.0</string>
</dict>
</plist>
PLIST

# Ad-hoc potpis da macOS dopusti pokretanje lokalnog builda.
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "Done → $APP"
echo "Pokreni s:  open \"$APP\""

#!/bin/bash
set -euo pipefail

APP_NAME="Yutools"
BUNDLE_ID="com.yxyyds666.Yutools"
BUILD_DIR=".build/release"
VERSION="${1:-1.0.$(git rev-list --count HEAD 2>/dev/null || echo 0)}"

echo "==> Packaging $APP_NAME v$VERSION"

# Build release binary
swift build -c release

# Create .app bundle structure
APP_BUNDLE="$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy bundled tools/resources
if [ -d "Sources/AndroidToolbox/Resources" ]; then
  cp -R "Sources/AndroidToolbox/Resources/" "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>羽工具箱</string>
    <key>CFBundleDisplayName</key>
    <string>羽工具箱</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "==> Created $APP_BUNDLE"

# Create DMG
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_TEMP="${APP_NAME}-temp.dmg"
DMG_DIR="dmg-contents"

rm -rf "$DMG_DIR" "$DMG_TEMP" "$DMG_NAME"
mkdir -p "$DMG_DIR"

# Copy .app into DMG staging
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Create compressed DMG
hdiutil create -volname "羽工具箱" \
  -srcfolder "$DMG_DIR" \
  -ov -format UDZO \
  -size 512m \
  "$DMG_TEMP"

# Convert to read-only compressed
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_NAME"
rm -rf "$DMG_TEMP" "$DMG_DIR"

echo "==> Created $DMG_NAME ($(du -h "$DMG_NAME" | cut -f1))"
echo "==> Done"

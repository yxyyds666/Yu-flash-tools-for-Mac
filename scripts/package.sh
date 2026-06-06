#!/bin/bash
set -euo pipefail

APP_NAME="Yutools"
BUNDLE_ID="com.yxyyds666.Yutools"
BUILD_DIR=".build/release"
VERSION="${1:-1.0.$(git rev-list --count HEAD 2>/dev/null || echo 0)}"
SKIP_BUILD="${SKIP_BUILD:-0}"

echo "==> Packaging $APP_NAME v$VERSION"

# Build release binary (skippable when CI already built)
if [ "$SKIP_BUILD" = "1" ] && [ -x "$BUILD_DIR/$APP_NAME" ]; then
  echo "==> Skipping swift build (SKIP_BUILD=1, binary present)"
else
  swift build -c release
fi

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

# Generate .icns from app-icon.png
ICON_SRC="Sources/AndroidToolbox/Resources/app-icon.png"
if [ -f "$ICON_SRC" ]; then
  ICONSET_DIR="AppIcon.iconset"
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"

  for SIZE in 16 32 128 256 512; do
    sips -z $SIZE $SIZE "$ICON_SRC" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}.png" &>/dev/null
    DOUBLE=$((SIZE * 2))
    sips -z $DOUBLE $DOUBLE "$ICON_SRC" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png" &>/dev/null
  done
  # Also create 1024x1024 for 512@2x
  sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" &>/dev/null

  iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
  rm -rf "$ICONSET_DIR"
fi

# Create PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "==> Created $APP_BUNDLE"

# Create DMG (single-pass, auto-sized, UDZO compressed)
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_DIR="dmg-contents"

rm -rf "$DMG_DIR" "$DMG_NAME"
mkdir -p "$DMG_DIR"

cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "羽工具箱" \
  -srcfolder "$DMG_DIR" \
  -ov -format UDZO \
  "$DMG_NAME"

rm -rf "$DMG_DIR"

echo "==> Created $DMG_NAME ($(du -h "$DMG_NAME" | cut -f1))"
echo "==> Done"

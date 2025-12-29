#!/bin/bash
set -e

APP_NAME="CatOnScreen"
BUNDLE_ID="com.kiranjd.catonscreen"
BUILD_DIR=".build/release"
APP_DIR="$APP_NAME.app"

echo "Building $APP_NAME..."

# Build with SwiftPM
swift build -c release

# Create app bundle structure
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"

# Copy resources from SwiftPM bundle
RESOURCE_BUNDLE=".build/arm64-apple-macosx/release/${APP_NAME}_CatOnScreen.bundle"
if [ -d "$RESOURCE_BUNDLE/Assets" ]; then
    cp -r "$RESOURCE_BUNDLE/Assets" "$APP_DIR/Contents/Resources/"
    echo "Copied assets from bundle"
elif [ -d "$BUILD_DIR/${APP_NAME}_CatOnScreen.bundle/Assets" ]; then
    cp -r "$BUILD_DIR/${APP_NAME}_CatOnScreen.bundle/Assets" "$APP_DIR/Contents/Resources/"
    echo "Copied assets from fallback bundle path"
else
    echo "Warning: Resource bundle not found"
    # Fallback: copy from source
    cp Sources/CatOnScreen/Resources/Assets/*.png "$APP_DIR/Contents/Resources/" 2>/dev/null || true
fi

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Cat On Screen</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc sign
codesign --force --deep --sign - "$APP_DIR"

echo "Done! App bundle created at $APP_DIR"
echo "To run: open $APP_DIR"

#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="WinClipMac"

echo "🔨 Building WinClipMac..."

# Build with Swift Package Manager
swift build -c release --package-path "$PROJECT_DIR"

# Create app bundle
APP_BUNDLE="$BUILD_DIR/release/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "$PROJECT_DIR/Sources/WinClipMac/Resources/Info.plist" "$APP_BUNDLE/Contents/"

echo "✅ Build complete!"
echo ""
echo "App bundle created at: $APP_BUNDLE"
echo ""
echo "To run (menu bar only mode):"
echo "  $PROJECT_DIR/run.sh"
echo "  OR"
echo "  $BUILD_DIR/release/$APP_NAME"
echo ""
echo "To run as regular app (shows in Dock):"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "For auto-start, add run.sh to Login Items in System Settings → General → Login Items"

# Optionally run the app
if [[ "$1" == "--run" ]]; then
    echo "🚀 Launching WinClipMac (menu bar mode)..."
    cd "$PROJECT_DIR"
    exec .build/release/WinClipMac
fi
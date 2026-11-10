#!/bin/bash

# WinClipMac - Launch Script
# Run this script to start the clipboard manager
# For automatic startup, add this script to Login Items in System Settings

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="WinClipMac"
EXECUTABLE="$BUILD_DIR/release/$APP_NAME"

# Build if needed
if [ ! -f "$EXECUTABLE" ] || [ "$PROJECT_DIR/Sources/WinClipMac/main.swift" -nt "$EXECUTABLE" ]; then
    echo "🔨 Building WinClipMac..."
    cd "$PROJECT_DIR"
    swift build -c release
fi

# Check if already running
if pgrep -f "$APP_NAME" > /dev/null; then
    echo "⚠️  WinClipMac is already running"
    exit 0
fi

echo "🚀 Starting WinClipMac..."
echo "   Press Cmd+Shift+V to open clipboard history"
echo "   Click 📋 in menu bar for more options"
echo ""

# Run in background
cd "$PROJECT_DIR"
exec "$EXECUTABLE"
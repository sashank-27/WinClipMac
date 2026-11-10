#!/bin/bash

# WinClipMac Installer Builder
# Creates professional .dmg and .pkg installers

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
RELEASE_DIR="$PROJECT_DIR/.release"
APP_NAME="WinClipMac"
VERSION="1.0.0"
IDENTIFIER="com.winclipmac.app"

echo "📦 Building WinClipMac Installers v$VERSION"

# Clean and create release directory
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Build the app first
echo "🔨 Building app..."
cd "$PROJECT_DIR"
swift build -c release

# Create app bundle
APP_BUNDLE="$BUILD_DIR/release/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "$PROJECT_DIR/Sources/WinClipMac/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Codesign the app (ad-hoc for development)
echo "🔐 Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

# ============================================
# 1. Create DMG with Drag-and-Drop to Applications
# ============================================
echo "💿 Creating DMG installer..."

DMG_DIR="$RELEASE_DIR/dmg"
mkdir -p "$DMG_DIR"

# Copy app to DMG staging
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
DMG_NAME="$APP_NAME-$VERSION.dmg"
hdiutil create -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$RELEASE_DIR/$DMG_NAME"

echo "✅ DMG created: $RELEASE_DIR/$DMG_NAME"

# ============================================
# 2. Create PKG Installer (for permissions, auto-start, etc.)
# ============================================
echo "📦 Creating PKG installer..."

PKG_DIR="$RELEASE_DIR/pkg"
PKG_ROOT="$PKG_DIR/root"
PKG_SCRIPTS="$PKG_DIR/scripts"
PKG_RESOURCES="$PKG_DIR/resources"

mkdir -p "$PKG_ROOT/Applications"
mkdir -p "$PKG_SCRIPTS"
mkdir -p "$PKG_RESOURCES"

# Copy app to pkg root
cp -R "$APP_BUNDLE" "$PKG_ROOT/Applications/"

# Create preinstall script (check macOS version)
cat > "$PKG_SCRIPTS/preinstall" << 'EOF'
#!/bin/bash
# Check macOS version
MIN_VERSION="13.0"
CURRENT_VERSION=$(sw_vers -productVersion)

if [[ $(echo "$CURRENT_VERSION $MIN_VERSION" | awk '{print ($1 >= $2)}') -eq 0 ]]; then
    echo "ERROR: WinClipMac requires macOS 13.0 (Ventura) or later. Current: $CURRENT_VERSION"
    exit 1
fi

# Kill existing instance
pkill -9 "WinClipMac" 2>/dev/null || true

exit 0
EOF
chmod +x "$PKG_SCRIPTS/preinstall"

# Create postinstall script (setup permissions, login item)
cat > "$PKG_SCRIPTS/postinstall" << 'EOF'
#!/bin/bash

APP_PATH="/Applications/WinClipMac.app"
BUNDLE_ID="com.winclipmac.app"

# Set proper permissions
chown -R "$USER:staff" "$APP_PATH" 2>/dev/null || true
chmod -R 755 "$APP_PATH" 2>/dev/null || true

# Remove quarantine attribute
xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_PATH" 2>/dev/null || true

# Add to Login Items (requires user approval)
# We'll use a LaunchAgent approach instead for auto-start
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENT_DIR"

cat > "$LAUNCH_AGENT_DIR/com.winclipmac.plist" << LAUNCHEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.winclipmac</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_PATH/Contents/MacOS/WinClipMac</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>
LAUNCHEOF

# Load the launch agent (as current user)
launchctl bootstrap gui/$(id -u) "$LAUNCH_AGENT_DIR/com.winclipmac.plist" 2>/dev/null || true

# Prompt for Accessibility permission
echo ""
echo "⚠️  IMPORTANT: WinClipMac requires Accessibility permission for global hotkey (Cmd+Shift+V)"
echo "   Please grant it in: System Settings → Privacy & Security → Accessibility"
echo "   Add WinClipMac and enable the toggle"
echo ""

# Open System Settings to Accessibility pane
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true

exit 0
EOF
chmod +x "$PKG_SCRIPTS/postinstall"

# Create uninstall script
cat > "$PKG_SCRIPTS/preuninstall" << 'EOF'
#!/bin/bash
# Stop and remove launch agent
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.winclipmac.plist"
launchctl bootout gui/$(id -u) "$LAUNCH_AGENT" 2>/dev/null || true
rm -f "$LAUNCH_AGENT"

# Kill app
pkill -9 "WinClipMac" 2>/dev/null || true

exit 0
EOF
chmod +x "$PKG_SCRIPTS/preuninstall"

# Build component package
COMPONENT_PKG="$PKG_DIR/WinClipMacComponent.pkg"
pkgbuild --root "$PKG_ROOT" \
    --scripts "$PKG_SCRIPTS" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --install-location "/" \
    "$COMPONENT_PKG"

# Create distribution XML
cat > "$PKG_DIR/distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>WinClipMac</title>
    <organization>com.winclipmac</organization>
    <domains enable_anywhere="true" enable_currentUserHome="true" enable_localSystem="true"/>
    <options customize="never" require-scripts="false" rootVolumeOnly="false"/>
    
    <welcome file="welcome.html" mime-type="text/html"/>
    <license file="license.html" mime-type="text/html"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>
    
    <pkg-ref id="$IDENTIFIER"/>
    
    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>
    
    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
    
    <pkg-ref id="$IDENTIFIER" version="$VERSION" onConclusion="none">WinClipMacComponent.pkg</pkg-ref>
</installer-gui-script>
EOF

# Create welcome HTML
cat > "$PKG_RESOURCES/welcome.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px; line-height: 1.6; }
        h1 { color: #1d1d1f; }
        .icon { font-size: 48px; margin-bottom: 10px; }
        .features { margin-top: 20px; }
        .feature { margin: 10px 0; }
    </style>
</head>
<body>
    <div class="icon">📋</div>
    <h1>Welcome to WinClipMac</h1>
    <p>Windows-style clipboard manager for macOS. Press <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd> to access your clipboard history.</p>
    
    <div class="features">
        <div class="feature">📝 Text, 🖼️ Images, 📁 Files, 📄 RTF support</div>
        <div class="feature">📌 Pin important items</div>
        <div class="feature">🔍 Real-time search</div>
        <div class="feature">✅ Copy confirmation toast</div>
        <div class="feature">💾 Persistent history across restarts</div>
    </div>
    
    <p><strong>Requires:</strong> macOS 13.0 (Ventura) or later</p>
</body>
</html>
EOF

# Create license HTML
cat > "$PKG_RESOURCES/license.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px; line-height: 1.6; max-width: 600px; }
        h1 { color: #1d1d1f; }
    </style>
</head>
<body>
    <h1>MIT License</h1>
    <p>Copyright (c) 2026 Sashank Bulusu</p>
    <p>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:</p>
    <p>The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.</p>
    <p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.</p>
</body>
</html>
EOF

# Create conclusion HTML
cat > "$PKG_RESOURCES/conclusion.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px; line-height: 1.6; text-align: center; }
        h1 { color: #1d1d1f; }
        .icon { font-size: 48px; margin-bottom: 10px; }
        .next-steps { text-align: left; margin-top: 20px; padding: 15px; background: #f5f5f7; border-radius: 8px; }
    </style>
</head>
<body>
    <div class="icon">📋</div>
    <h1>Installation Complete!</h1>
    <p>WinClipMac has been installed to your Applications folder.</p>
    
    <div class="next-steps">
        <h3>Next Steps:</h3>
        <ol>
            <li><strong>Grant Accessibility Permission</strong> (required for Cmd+Shift+V):
                <br>System Settings → Privacy & Security → Accessibility → Add WinClipMac
            </li>
            <li><strong>Launch WinClipMac</strong> from Applications or Spotlight</li>
            <li><strong>Press Cmd+Shift+V</strong> to open clipboard history</li>
        </ol>
        <p>The app runs in the menu bar (📋 icon). No Dock icon appears.</p>
    </div>
</body>
</html>
EOF

# Build final product package
PRODUCT_PKG="$RELEASE_DIR/WinClipMac-$VERSION.pkg"
productbuild --distribution "$PKG_DIR/distribution.xml" \
    --package-path "$PKG_DIR" \
    --resources "$PKG_RESOURCES" \
    "$PRODUCT_PKG"

# Sign the package (ad-hoc)
productsign --sign - "$PRODUCT_PKG" "$RELEASE_DIR/WinClipMac-$VERSION-signed.pkg" 2>/dev/null || cp "$PRODUCT_PKG" "$RELEASE_DIR/WinClipMac-$VERSION-signed.pkg"

echo "✅ PKG created: $RELEASE_DIR/WinClipMac-$VERSION-signed.pkg"

# ============================================
# Summary
# ============================================
echo ""
echo "🎉 Installers created successfully!"
echo ""
echo "📁 Release directory: $RELEASE_DIR"
echo ""
ls -lh "$RELEASE_DIR"
echo ""
echo "📦 DMG: Drag WinClipMac.app to Applications folder"
echo "📦 PKG: Double-click to run installer with guided setup"
echo ""
echo "To test PKG: open \"$RELEASE_DIR/WinClipMac-$VERSION-signed.pkg\""
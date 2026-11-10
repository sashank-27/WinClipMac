# WinClipMac - Windows-style Clipboard Manager for macOS

A native macOS clipboard manager that mimics the Windows clipboard history (Win+V) functionality. Access your clipboard history with a global keyboard shortcut.

## Features

- **Global Hotkey**: Press `Cmd+Shift+V` to open clipboard history (like Win+V on Windows)
- **Menu Bar Access**: Click the 📋 icon in the menu bar (right side, near clock)
- **Clipboard History**: Automatically tracks copied text, images, files, and RTF content
- **Pin Items**: Pin frequently used items to keep them at the top
- **Search**: Filter clipboard history in real-time
- **Persistent Storage**: History survives app restarts
- **Native macOS App**: Built with Swift and SwiftUI for best performance

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools (for building)

## Building from Source

```bash
cd ~/Desktop/WinClipMac
./build.sh
```

The app bundle will be created at `.build/release/WinClipMac.app`

## Running

### Option 1: Menu Bar Only Mode (Recommended)
This runs as a true menu bar app (no Dock icon):
```bash
./run.sh
# OR directly:
./build/release/WinClipMac
```

### Option 2: Regular App Mode (Shows in Dock)
```bash
./build.sh --run
# OR
open .build/release/WinClipMac.app
```

**Note**: On first launch via `open`, macOS may show a Dock icon briefly. The menu bar only mode (Option 1) is the intended way to run this app continuously in the background.

## Usage

1. **First Launch**: The app will request Accessibility permissions (needed for global hotkey `Cmd+Shift+V`)
   - Grant it in: System Settings → Privacy & Security → Accessibility
2. **Copy Content**: Copy any text, image, or file as usual
3. **Open History**: Press `Cmd+Shift+V` or click the 📋 menu bar icon
4. **Select Item**: Click an item or use arrow keys + Enter to paste
5. **Pin Items**: Click the pin icon to keep important items at the top
6. **Search**: Type in the search box to filter history
7. **Right-click** the 📋 icon for Quit/Preferences

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+V` | Open clipboard history |
| `Enter` | Copy selected item to clipboard and paste |
| `Escape` | Close history window |
| `↑/↓` | Navigate history |

## Auto-Start on Login

1. Open System Settings → General → Login Items
2. Click `+` under "Open at Login"
3. Select `run.sh` from the WinClipMac folder
4. The app will start automatically on login as a menu bar app

## Project Structure

```
WinClipMac/
├── Package.swift              # Swift Package Manager config
├── build.sh                   # Build script
├── run.sh                     # Launch script (menu bar mode)
├── README.md                  # This file
├── Sources/WinClipMac/
│   ├── main.swift             # App entry point & menu bar
│   ├── ClipboardManager.swift # Clipboard history model & persistence
│   ├── ClipboardMonitor.swift # Clipboard change detection
│   └── ClipboardHistoryView.swift # SwiftUI clipboard history UI
└── Resources/
    └── Info.plist             # App bundle configuration
```

## Technical Details

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with Combine
- **Persistence**: UserDefaults (JSON encoding)
- **Global Hotkeys**: NSEvent global monitor
- **Menu Bar**: NSStatusItem
- **Activation Policy**: Accessory (menu bar only)

## Permissions

The app requires **Accessibility** permission to register global hotkeys. Grant it in:
System Settings → Privacy & Security → Accessibility

## License

MIT License - Feel free to use and modify!
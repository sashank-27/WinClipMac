# WinClipMac v1.0.0

**Windows-style clipboard manager for macOS** - Press `Cmd+Shift+V` to access your clipboard history, just like `Win+V` on Windows.

## Features

| Feature | Description |
|---------|-------------|
| 🎯 **Global Hotkey** | `Cmd+Shift+V` opens clipboard history instantly |
| 📋 **Menu Bar Access** | Click the 📋 icon in the top-right menu bar |
| 📝 **Text History** | Automatically captures all copied text |
| 🖼️ **Image Support** | Screenshots (`Cmd+Shift+Ctrl+4`), copied images from browser/apps |
| 📁 **File Tracking** | Remembers copied file paths |
| 📄 **RTF Support** | Preserves rich text formatting |
| 📌 **Pin Items** | Keep frequently used clips at the top |
| 🔍 **Real-time Search** | Filter history instantly as you type |
| ✅ **Copy Confirmation** | Toast notification when item is copied |
| 💾 **Persistent Storage** | History survives app restarts and reboots |
| ⚡ **Single-Click Copy** | Click any item to copy to clipboard |

## Installation

### Option 1: Download Release (Recommended)
1. Go to [Releases](../../releases)
2. Download `WinClipMac.app.zip`
3. Unzip and drag to Applications (or run from anywhere)

### Option 2: Build from Source
```bash
git clone https://github.com/sashank-27/WinClipMac.git
cd WinClipMac
./build.sh
# Run: ./run.sh  (menu bar only mode)
# Or: open .build/release/WinClipMac.app
```

## First Run Setup

1. **Launch the app** - It runs in the menu bar (no Dock icon)
2. **Grant Accessibility Permission** (required for global hotkey):
   - System Settings → Privacy & Security → Accessibility
   - Click `+` → Select `WinClipMac` → Enable
3. **Restart app** if prompted: `pkill WinClipMac && open /path/to/WinClipMac.app`

## Usage

| Action | Shortcut |
|--------|----------|
| Open clipboard history | `Cmd+Shift+V` |
| Open via menu bar | Click 📋 icon |
| Copy item to clipboard | Click item in history |
| Paste | `Cmd+V` (after selecting item) |
| Pin/Unpin item | Hover → Click 📌 |
| Delete item | Hover → Click 🗑️ |
| Search history | Type in search box |
| Right-click menu | Right-click 📋 icon |

## Screenshots

*Menu bar access with history popover showing text, images, and files*

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools (for building)

## Architecture

- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Architecture**: MVVM with Combine
- **Persistence**: UserDefaults (JSON)
- **Global Hotkeys**: Carbon Event Manager API
- **Menu Bar**: NSStatusItem (accessory activation policy)

## Auto-Start on Login

Add `run.sh` to System Settings → General → Login Items for automatic startup as a menu bar app.

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Acknowledgments

- Inspired by Windows Clipboard History (`Win+V`)
- Built for macOS users who miss this feature
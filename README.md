# WinClipMac

[![Release](https://img.shields.io/github/v/release/sashank-27/WinClipMac?include_prereleases&label=Latest%20Release)](https://github.com/sashank-27/WinClipMac/releases)
[![License](https://img.shields.io/github/license/sashank-27/WinClipMac)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)](https://github.com/sashank-27/WinClipMac)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://swift.org)
[![Build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/sashank-27/WinClipMac/actions)

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

## Quick Start

### Download (Easiest)
1. Download latest release: [WinClipMac.app.zip](../../releases/latest/download/WinClipMac.app.zip)
2. Unzip and run (or drag to Applications)

### Build from Source
```bash
git clone https://github.com/sashank-27/WinClipMac.git
cd WinClipMac
./build.sh
./run.sh
```

## First Run Setup

1. **Launch** - App runs in menu bar (no Dock icon)
2. **Grant Accessibility** (for `Cmd+Shift+V` hotkey):
   - System Settings → Privacy & Security → Accessibility
   - Add `WinClipMac` and enable
3. **Restart** if needed: `pkill WinClipMac && open WinClipMac.app`

## Usage

| Action | Shortcut |
|--------|----------|
| Open history | `Cmd+Shift+V` |
| Open via menu bar | Click 📋 icon |
| Copy item | Click item |
| Paste | `Cmd+V` |
| Pin/Unpin | Hover → 📌 |
| Delete | Hover → 🗑️ |
| Search | Type in search box |

## Screenshots

*Menu bar access showing clipboard history with text, images, and files*

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

Add `run.sh` to System Settings → General → Login Items for automatic startup.

## License

[MIT License](LICENSE) - Free to use and modify.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Changelog

See [Releases](../../releases) for version history.

---

**Star ⭐ this repo if you find it useful!**
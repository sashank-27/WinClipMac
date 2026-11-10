import SwiftUI
import AppKit
import Carbon

// Global reference to AppDelegate for hotkey callback
private var sharedAppDelegate: AppDelegate?

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardMonitor: ClipboardMonitor?
    var hotKeyRef: EventHotKeyRef?
    var eventHandlerRef: EventHandlerRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        sharedAppDelegate = self
        setupMenuBar()
        setupClipboardMonitor()
        setupGlobalHotKey()
        requestAccessibilityPermission()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else { return }
        
        if let button = statusItem.button {
            button.title = "📋"
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    func setupClipboardMonitor() {
        clipboardMonitor = ClipboardMonitor()
        clipboardMonitor?.clipboardManager = ClipboardManager.shared
        clipboardMonitor?.startMonitoring()
    }
    
    func setupGlobalHotKey() {
        let hotKeyID = EventHotKeyID(signature: fourCharCode("WCLP"), id: 1)
        
        let eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        ]
        
        let callback: EventHandlerProcPtr = { (nextHandler, theEvent, userData) -> OSStatus in
            DispatchQueue.main.async {
                sharedAppDelegate?.showPopover(nil)
            }
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, eventTypes, nil, &eventHandlerRef)
        
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if registerStatus != noErr {
            // Fallback: Cmd+Option+V
            RegisterEventHotKey(
                UInt32(kVK_ANSI_V),
                UInt32(cmdKey | optionKey),
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
        }
        
        // Also add NSEvent monitor as fallback
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) && event.keyCode == 9 {
                self.showPopover(nil)
            }
        }
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        sharedAppDelegate = nil
    }
    
    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            showPopover(sender)
            return
        }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Show Clipboard History", action: #selector(showPopover(_:)), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences(_:)), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit WinClipMac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.frame.height), in: sender)
        } else {
            showPopover(sender)
        }
    }
    
    @objc func showPopover(_ sender: Any?) {
        if let popover = popover, popover.isShown {
            popover.performClose(sender)
        } else {
            createPopover()
            if let button = statusItem?.button {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover?.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    func createPopover() {
        let contentView = ClipboardHistoryView(clipboardMonitor: clipboardMonitor!)
            .environmentObject(ClipboardManager.shared)
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 380, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: contentView)
        popover?.delegate = self
    }
    
    @objc func openPreferences(_ sender: Any?) {
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        popover = nil
    }
}

func fourCharCode(_ string: String) -> UInt32 {
    let data = string.data(using: .macOSRoman)!
    var result: UInt32 = 0
    for byte in data {
        result = (result << 8) | UInt32(byte)
    }
    return result
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
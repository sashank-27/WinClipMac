import Foundation
import AppKit
import Combine

class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    weak var clipboardManager: ClipboardManager?
    
    init() {
        lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        timer?.fire()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if let item = parseClipboardContent() {
            DispatchQueue.main.async { [weak self] in
                self?.clipboardManager?.addItem(item)
            }
        }
    }
    
    private func parseClipboardContent() -> ClipboardItem? {
        if let image = NSImage(pasteboard: pasteboard) {
            if let tiffData = image.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                let base64String = pngData.base64EncodedString()
                let preview = "Image (\(Int(image.size.width))x\(Int(image.size.height)))"
                return ClipboardItem(content: base64String, type: .image, preview: preview)
            }
        }
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstUrl = urls.first {
            let preview = "File: \(firstUrl.lastPathComponent)"
            return ClipboardItem(content: firstUrl.absoluteString, type: .file, preview: preview)
        }
        
        if let rtfData = pasteboard.data(forType: .rtf) {
            let base64String = rtfData.base64EncodedString()
            if let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                let preview = String(attributedString.string.prefix(100))
                return ClipboardItem(content: base64String, type: .rtf, preview: preview)
            }
        }
        
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let preview = String(string.prefix(100)).replacingOccurrences(of: "\n", with: " ")
            return ClipboardItem(content: string, type: .text, preview: preview)
        }
        
        return nil
    }
}
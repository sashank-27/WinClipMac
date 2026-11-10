import Foundation
import AppKit
import Combine

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var history: [ClipboardItem] = []
    @Published var pinnedItems: [ClipboardItem] = []
    
    private let maxHistorySize = 100
    private var lastChangeCount: Int = 0
    
    private init() {
        loadHistory()
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func addItem(_ item: ClipboardItem) {
        // Don't add duplicates
        if let existingIndex = history.firstIndex(where: { $0.content == item.content && $0.type == item.type }) {
            // Move to top
            history.remove(at: existingIndex)
        }
        
        history.insert(item, at: 0)
        
        // Trim history
        if history.count > maxHistorySize {
            history = Array(history.prefix(maxHistorySize))
        }
        
        saveHistory()
    }
    
    func pinItem(_ item: ClipboardItem) {
        if !pinnedItems.contains(where: { $0.id == item.id }) {
            item.isPinned = true
            pinnedItems.insert(item, at: 0)
            saveHistory()
        }
    }
    
    func unpinItem(_ item: ClipboardItem) {
        item.isPinned = false
        pinnedItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func deleteItem(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        pinnedItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            pasteboard.setString(item.content, forType: .string)
        case .image:
            if let imageData = Data(base64Encoded: item.content),
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        case .file:
            if let url = URL(string: item.content) {
                pasteboard.writeObjects([url as NSURL])
            }
        case .rtf:
            if let data = Data(base64Encoded: item.content) {
                pasteboard.setData(data, forType: .rtf)
            }
        }
    }
    
    private func saveHistory() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(history) {
            UserDefaults.standard.set(data, forKey: "clipboardHistory")
        }
        if let data = try? encoder.encode(pinnedItems) {
            UserDefaults.standard.set(data, forKey: "pinnedItems")
        }
    }
    
    private func loadHistory() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
           let items = try? decoder.decode([ClipboardItem].self, from: data) {
            history = items
        }
        if let data = UserDefaults.standard.data(forKey: "pinnedItems"),
           let items = try? decoder.decode([ClipboardItem].self, from: data) {
            pinnedItems = items
        }
    }
}

enum ClipboardItemType: String, Codable {
    case text
    case image
    case file
    case rtf
}

class ClipboardItem: Identifiable, ObservableObject, Codable, Equatable {
    let id: UUID
    let content: String
    let type: ClipboardItemType
    let timestamp: Date
    let preview: String
    @Published var isPinned: Bool = false
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, type, timestamp, preview, isPinned
    }
    
    init(content: String, type: ClipboardItemType, preview: String? = nil) {
        self.id = UUID()
        self.content = content
        self.type = type
        self.timestamp = Date()
        self.preview = preview ?? String(content.prefix(100))
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(ClipboardItemType.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        preview = try container.decode(String.self, forKey: .preview)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(preview, forKey: .preview)
        try container.encode(isPinned, forKey: .isPinned)
    }
}
import SwiftUI
import AppKit

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var showCopiedToast = false
    @State private var copiedText = ""
    @FocusState private var isSearchFocused: Bool
    
    var filteredItems: [ClipboardItem] {
        let pinnedIDs = Set(clipboardManager.pinnedItems.map { $0.id })
        let unpinnedItems = clipboardManager.history.filter { !pinnedIDs.contains($0.id) }
        let allItems = clipboardManager.pinnedItems + unpinnedItems
        
        if searchText.isEmpty {
            return allItems
        }
        
        return allItems.filter { item in
            item.content.localizedCaseInsensitiveContains(searchText) ||
            item.preview.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Search
                searchView
                
                Divider()
                
                // Clipboard items
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(item: item, onCopy: { text in
                                    showCopiedToast(text: text)
                                })
                                    .environmentObject(clipboardManager)
                                
                                if index != filteredItems.count - 1 {
                                    Divider()
                                        .padding(.leading, 44)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Divider()
                
                // Footer with shortcuts
                footerView
            }
            .frame(width: 380, height: 500)
            .background(Color(NSColor.controlBackgroundColor))
            .onAppear {
                isSearchFocused = true
            }
            
            // Toast notification
            if showCopiedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Copied: \(copiedText)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: showCopiedToast)
                }
            }
        }
    }
    
    func showCopiedToast(text: String) {
        copiedText = String(text.prefix(40))
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    var headerView: some View {
        HStack {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
            
            Text("WinClipMac")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            Text("\(clipboardManager.history.count) items")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Button(action: {
                clipboardManager.clearHistory()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear History")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    var searchView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 13))
            
            TextField("Search clipboard...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFocused)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(searchText.isEmpty ? "No clipboard history yet" : "No matches found")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Text("Copy something to get started")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    var footerView: some View {
        HStack {
            Label("⌘⇧V to open", systemImage: "keyboard")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Label("Click to copy", systemImage: "hand.tap")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct ClipboardItemRow: View {
    @ObservedObject var item: ClipboardItem
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var isHovered = false
    let onCopy: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Item icon/preview
            itemIcon
                .frame(width: 32, height: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 8) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
                    
                    Text(item.type.rawValue.capitalized)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // Actions (shown on hover)
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: {
                        if item.isPinned {
                            clipboardManager.unpinItem(item)
                        } else {
                            clipboardManager.pinItem(item)
                        }
                    }) {
                        Image(systemName: item.isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 12))
                            .foregroundColor(item.isPinned ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin" : "Pin")
                    
                    Button(action: {
                        clipboardManager.deleteItem(item)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            clipboardManager.copyToPasteboard(item)
            onCopy(item.preview)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
        )
    }
    
    @ViewBuilder
    var itemIcon: some View {
        switch item.type {
        case .text:
            Image(systemName: "doc.text")
                .font(.system(size: 16))
                .foregroundColor(.blue)
        case .image:
            if let data = Data(base64Encoded: item.content),
               let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .cornerRadius(4)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }
        case .file:
            Image(systemName: "doc")
                .font(.system(size: 16))
                .foregroundColor(.purple)
        case .rtf:
            Image(systemName: "doc.richtext")
                .font(.system(size: 16))
                .foregroundColor(.orange)
        }
    }
}

// Preview
struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let monitor = ClipboardMonitor()
        let manager = ClipboardManager.shared
        
        // Add some sample data
        manager.history = [
            ClipboardItem(content: "Hello, World!", type: .text),
            ClipboardItem(content: "https://github.com", type: .text),
            ClipboardItem(content: "print('Hello')", type: .text),
        ]
        
        return ClipboardHistoryView(clipboardMonitor: monitor)
            .environmentObject(manager)
            .frame(width: 380, height: 500)
    }
}
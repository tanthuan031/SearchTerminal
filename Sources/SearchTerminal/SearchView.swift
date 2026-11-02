import SwiftUI
import Cocoa

public struct SearchView: View {
    @ObservedObject var viewModel = SearchViewModel.shared
    @ObservedObject var indexer = FolderIndexer.shared
    @FocusState private var isFieldFocused: Bool
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Header
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search folders or files...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 19, weight: .regular))
                    .focused($isFieldFocused)
                    .onChange(of: viewModel.searchText) { _, newText in
                        viewModel.performSearch(query: newText)
                    }
                
                if indexer.isIndexing {
                    ProgressView()
                        .controlSize(.small)
                        .help("Indexing allowed folders...")
                }
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            
            Picker("", selection: $viewModel.searchMode) {
                ForEach(SearchViewModel.SearchMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
            
            Divider()
            
            // Search Results List
            if viewModel.results.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: viewModel.searchText.isEmpty ? "folder.badge.questionmark" : "magnifyingglass")
                        .font(.system(size: 34))
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.searchText.isEmpty ? "No folders found. Check Settings to add allowed folders." : "No matching folders found for \"\(viewModel.searchText)\"")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    if viewModel.searchText.isEmpty {
                        Button("Open Settings") {
                            viewModel.showSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: 320)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, item in
                                ResultRowView(item: item, isSelected: index == viewModel.selectedIndex)
                                    .id(item.id)
                                    .onTapGesture {
                                        viewModel.selectedIndex = index
                                    }
                                    .simultaneousGesture(TapGesture(count: 2).onEnded {
                                        viewModel.openTerminal(item: item)
                                    })
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                    }
                    .frame(height: min(CGFloat(viewModel.results.count) * 54.0 + 12.0, 420))
                    .onChange(of: viewModel.selectedIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            if let target = viewModel.results[safe: newIndex] {
                                proxy.scrollTo(target.id, anchor: .center)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer with shortcuts and status
            HStack(spacing: 12) {
                Text("\(viewModel.results.count) results")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Shortcut badges
                HStack(spacing: 10) {
                    ShortcutBadge(key: "↩", label: "Terminal")
                        .onTapGesture {
                            viewModel.openTerminal()
                        }
                    ShortcutBadge(key: "⌘↩", label: "Finder")
                        .onTapGesture {
                            viewModel.revealInFinder()
                        }
                    ShortcutBadge(key: "⌘O", label: "VS Code")
                        .onTapGesture {
                            viewModel.openInVSCode()
                        }
                    
                    Button(action: {
                        viewModel.showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open Settings")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        }
        .frame(width: 660)
        .background(VisualEffectBackground())
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        .onAppear {
            isFieldFocused = true
            viewModel.performSearch()
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// Single Result Row View
struct ResultRowView: View {
    let item: SearchItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Folder / File Icon
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.path))
                .resizable()
                .frame(width: 28, height: 28)
            
            // Name and Breadcrumb path
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if !item.isDirectory {
                        Text("FILE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    let queryNorm = SearchViewModel.shared.searchText.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: nil).lowercased()
                    if !queryNorm.isEmpty && item.normalizedName == queryNorm {
                        Text("EXACT MATCH")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(isSelected ? Color.white.opacity(0.3) : Color.green.opacity(0.2))
                            .foregroundColor(isSelected ? .white : .green)
                            .cornerRadius(3)
                    }
                }
                
                Text(item.displayPath)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? Color.white.opacity(0.85) : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Action buttons on selected item
            if isSelected {
                HStack(spacing: 6) {
                    Button(action: {
                        SearchViewModel.shared.openTerminal(item: item)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "terminal")
                            Text("Terminal")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    
                    Button(action: {
                        SearchViewModel.shared.revealInFinder(item: item)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "folder")
                            Text("Finder")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    
                    Button(action: {
                        SearchViewModel.shared.openInVSCode(item: item)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                            Text("VS Code")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            isSelected ? Color.accentColor : Color.clear
        )
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
}

// Shortcut pill widget in footer
struct ShortcutBadge: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(4)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

// Frosted glass background for macOS
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

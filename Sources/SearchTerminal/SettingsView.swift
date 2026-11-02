import SwiftUI
import Cocoa

public struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared
    @ObservedObject var indexer = FolderIndexer.shared
    @Environment(\.presentationMode) var presentationMode
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("SearchTerminal Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Allowed Folders
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Allowed Folders (Thư mục cho phép tìm kiếm)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: addFolder) {
                                Label("Add Folder", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        
                        Text("SearchTerminal will search inside these root directories and their subfolders.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            if settings.allowedPaths.isEmpty {
                                Text("No folders added yet. Click 'Add Folder' to select.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(settings.allowedPaths, id: \.self) { path in
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.blue)
                                        Text((path as NSString).lastPathComponent)
                                            .fontWeight(.medium)
                                        Text(displayPath(for: path))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Spacer()
                                        Button(action: {
                                            settings.removePath(path)
                                            indexer.startIndexing()
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Search Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Options")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("Max subfolder depth (Độ sâu folder con):")
                            Stepper("\(settings.maxDepth) levels", value: $settings.maxDepth, in: 1...10)
                                .onChange(of: settings.maxDepth) { _, _ in
                                    indexer.startIndexing()
                                }
                        }
                        .font(.callout)
                    }
                    
                    Divider()
                    
                    // Hotkey & Terminal App
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Picker("Global HotKey:", selection: $settings.hotKeyPreset) {
                            ForEach(HotKeyPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .onChange(of: settings.hotKeyPreset) { _, newPreset in
                            HotKeyManager.shared.register(preset: newPreset)
                        }
                        
                        Picker("Preferred Terminal:", selection: $settings.terminalApp) {
                            ForEach(TerminalAppOption.allCases) { term in
                                Text(term.rawValue).tag(term)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Indexing Status
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if indexer.isIndexing {
                                HStack {
                                    ProgressView().controlSize(.small)
                                    Text("Indexing folders...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Indexed \(indexer.totalIndexedCount) items in \(String(format: "%.2f", indexer.lastIndexDuration))s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            indexer.startIndexing()
                        }) {
                            Label("Re-index Now", systemImage: "arrow.clockwise")
                        }
                        .disabled(indexer.isIndexing)
                    }
                }
                .padding()
            }
        }
        .frame(width: 540, height: 460)
    }
    
    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Choose Folder"
        panel.message = "Select folders to search within"
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                settings.addPath(url.path)
            }
            indexer.startIndexing()
        }
    }
    
    private func displayPath(for path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

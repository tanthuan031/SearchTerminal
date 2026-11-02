import Foundation
import Combine

public enum HotKeyPreset: String, CaseIterable, Identifiable {
    case optionSpace = "Option + Space (⌥ Space)"
    case cmdShiftSpace = "Cmd + Shift + Space (⌘⇧ Space)"
    case optionP = "Option + P (⌥ P)"
    case cmdShiftF = "Cmd + Shift + F (⌘⇧ F)"
    
    public var id: String { rawValue }
}

public enum TerminalAppOption: String, CaseIterable, Identifiable {
    case terminal = "Terminal.app"
    case iterm2 = "iTerm2"
    case warp = "Warp"
    
    public var id: String { rawValue }
    
    public var bundleIdentifier: String {
        switch self {
        case .terminal: return "com.apple.Terminal"
        case .iterm2: return "com.googlecode.iterm2"
        case .warp: return "dev.warp.Warp-Stable"
        }
    }
}

public class SettingsStore: ObservableObject {
    public static let shared = SettingsStore()
    
    private let defaults = UserDefaults.standard
    private let allowedPathsKey = "search_terminal_allowed_paths"
    private let searchFilesKey = "search_terminal_search_files"
    private let maxDepthKey = "search_terminal_max_depth"
    private let hotKeyKey = "search_terminal_hotkey"
    private let terminalAppKey = "search_terminal_app"
    
    @Published public var allowedPaths: [String] {
        didSet {
            defaults.set(allowedPaths, forKey: allowedPathsKey)
        }
    }
    
    @Published public var searchFiles: Bool {
        didSet {
            defaults.set(searchFiles, forKey: searchFilesKey)
        }
    }
    
    @Published public var maxDepth: Int {
        didSet {
            defaults.set(maxDepth, forKey: maxDepthKey)
        }
    }
    
    @Published public var hotKeyPreset: HotKeyPreset {
        didSet {
            defaults.set(hotKeyPreset.rawValue, forKey: hotKeyKey)
        }
    }
    
    @Published public var terminalApp: TerminalAppOption {
        didSet {
            defaults.set(terminalApp.rawValue, forKey: terminalAppKey)
        }
    }
    
    private init() {
        let home = NSHomeDirectory()
        
        // Default allowed paths: Desktop, Documents, Downloads, Projects (if exists)
        if let saved = defaults.stringArray(forKey: allowedPathsKey), !saved.isEmpty {
            self.allowedPaths = saved
        } else {
            var defaultsList: [String] = []
            let candidates = [
                "\(home)/Projects",
                "\(home)/Documents",
                "\(home)/Desktop",
                "\(home)/Developer",
                "\(home)/workspace"
            ]
            let fm = FileManager.default
            for path in candidates {
                if fm.fileExists(atPath: path) {
                    defaultsList.append(path)
                }
            }
            if defaultsList.isEmpty {
                defaultsList = ["\(home)/Documents", "\(home)/Desktop"]
            }
            self.allowedPaths = defaultsList
            defaults.set(defaultsList, forKey: allowedPathsKey)
        }
        
        self.searchFiles = defaults.bool(forKey: searchFilesKey)
        
        let depth = defaults.integer(forKey: maxDepthKey)
        self.maxDepth = depth > 0 ? depth : 5
        
        if let hotKeyRaw = defaults.string(forKey: hotKeyKey),
           let preset = HotKeyPreset(rawValue: hotKeyRaw) {
            self.hotKeyPreset = preset
        } else {
            self.hotKeyPreset = .optionSpace
        }
        
        if let termRaw = defaults.string(forKey: terminalAppKey),
           let term = TerminalAppOption(rawValue: termRaw) {
            self.terminalApp = term
        } else {
            self.terminalApp = .terminal
        }
    }
    
    public func addPath(_ path: String) {
        guard !allowedPaths.contains(path) else { return }
        allowedPaths.append(path)
    }
    
    public func removePath(at offsets: IndexSet) {
        allowedPaths.remove(atOffsets: offsets)
    }
    
    public func removePath(_ path: String) {
        allowedPaths.removeAll(where: { $0 == path })
    }
}


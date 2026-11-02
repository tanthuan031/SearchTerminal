import Foundation
import Cocoa

public struct AppActions {
    
    /// Opens the specified folder or file's parent in Terminal or selected terminal app
    public static func openTerminal(at targetPath: String, app: TerminalAppOption = SettingsStore.shared.terminalApp) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: targetPath, isDirectory: &isDir) else {
            return
        }
        
        let folderPath = isDir.boolValue ? targetPath : (targetPath as NSString).deletingLastPathComponent
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        
        switch app {
        case .terminal:
            process.arguments = ["-a", "Terminal", folderPath]
        case .iterm2:
            process.arguments = ["-a", "iTerm", folderPath]
        case .warp:
            process.arguments = ["-a", "Warp", folderPath]
        }
        
        do {
            try process.run()
        } catch {
            print("Failed to open terminal: \(error)")
            // Fallback to default Terminal
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            fallback.arguments = ["-a", "Terminal", folderPath]
            try? fallback.run()
        }
    }
    
    /// Reveals and highlights the folder or file in macOS Finder
    public static func revealInFinder(at targetPath: String) {
        let url = URL(fileURLWithPath: targetPath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    /// Opens the folder or file in Visual Studio Code
    public static func openInVSCode(at targetPath: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Visual Studio Code", targetPath]
        do {
            try process.run()
        } catch {
            print("Failed to open in VS Code: \(error)")
        }
    }
    
    /// Generic open with default macOS application
    public static func openDefault(at targetPath: String) {
        let url = URL(fileURLWithPath: targetPath)
        NSWorkspace.shared.open(url)
    }
}


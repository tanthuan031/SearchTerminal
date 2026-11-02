import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app (lives in menu bar and floating panel, no dock clutter)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup Menu Bar controller
        statusBarController = StatusBarController()
        
        // Setup Global Hotkey
        let hotKeyManager = HotKeyManager.shared
        hotKeyManager.onHotKeyPressed = {
            SpotlightPanelController.shared.toggle()
        }
        hotKeyManager.register(preset: SettingsStore.shared.hotKeyPreset)
        
        // Initial indexing of folders
        FolderIndexer.shared.startIndexing()
        
        // Show panel shortly after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            SpotlightPanelController.shared.show()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregister()
    }
}

@main
struct SearchTerminalMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}


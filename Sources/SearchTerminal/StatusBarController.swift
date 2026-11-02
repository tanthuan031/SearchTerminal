import Foundation
import Cocoa

public class StatusBarController {
    private var statusItem: NSStatusItem?
    
    public init() {
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        if let image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "SearchTerminal") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "⚡️"
        }
        
        button.action = #selector(statusBarButtonClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        // Right-click opens menu
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            // Left-click toggles search panel
            SpotlightPanelController.shared.toggle()
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        let openItem = NSMenuItem(title: "Open Search (\(SettingsStore.shared.hotKeyPreset.rawValue))",
                                  action: #selector(openSearch),
                                  keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
        let rescanItem = NSMenuItem(title: "Rescan Folders",
                                    action: #selector(rescanFolders),
                                    keyEquivalent: "r")
        rescanItem.target = self
        menu.addItem(rescanItem)
        
        let settingsItem = NSMenuItem(title: "Settings...",
                                      action: #selector(openSettings),
                                      keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit SearchTerminal",
                                  action: #selector(quitApp),
                                  keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // reset so next left-click triggers action directly
    }
    
    @objc private func openSearch() {
        SpotlightPanelController.shared.show()
    }
    
    @objc private func rescanFolders() {
        FolderIndexer.shared.startIndexing()
    }
    
    @objc private func openSettings() {
        SpotlightPanelController.shared.show()
        SearchViewModel.shared.showSettings = true
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}


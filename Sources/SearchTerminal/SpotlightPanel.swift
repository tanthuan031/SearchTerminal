import Foundation
import Cocoa
import SwiftUI

public class SpotlightPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
    }
    
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return true
    }
    
    public override func cancelOperation(_ sender: Any?) {
        SpotlightPanelController.shared.hide()
    }
}

public class SpotlightPanelController {
    public static let shared = SpotlightPanelController()
    
    private var panel: SpotlightPanel?
    private var localEventMonitor: Any?
    
    private init() {
        setupPanel()
        setupKeyMonitor()
    }
    
    private func setupPanel() {
        let panelRect = NSRect(x: 0, y: 0, width: 660, height: 450)
        let newPanel = SpotlightPanel(contentRect: panelRect)
        
        let hostingView = NSHostingView(rootView: SearchView())
        newPanel.contentView = hostingView
        
        self.panel = newPanel
    }
    
    private func setupKeyMonitor() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else {
                return event
            }
            
            let vm = SearchViewModel.shared
            
            // ESC key (53)
            if event.keyCode == 53 {
                self.hide()
                return nil
            }
            
            // Down Arrow (125)
            if event.keyCode == 125 {
                vm.selectNext()
                return nil
            }
            
            // Up Arrow (126)
            if event.keyCode == 126 {
                vm.selectPrevious()
                return nil
            }
            
            // Return / Enter (36)
            if event.keyCode == 36 {
                if event.modifierFlags.contains(.command) {
                    // Cmd + Return -> Finder
                    vm.revealInFinder()
                } else {
                    // Return -> Terminal
                    vm.openTerminal()
                }
                return nil
            }
            
            // Cmd + O -> VS Code
            if event.keyCode == 31 && event.modifierFlags.contains(.command) {
                vm.openInVSCode()
                return nil
            }
            
            // Cmd + , -> Settings
            if event.keyCode == 43 && event.modifierFlags.contains(.command) {
                vm.showSettings = true
                return nil
            }
            
            return event
        }
    }
    
    public func toggle() {
        if let panel = panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    public func show() {
        guard let panel = panel else { return }
        
        SearchViewModel.shared.searchText = ""
        SearchViewModel.shared.performSearch(query: "")
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let panelSize = panel.frame.size
            let x = screenRect.origin.x + (screenRect.width - panelSize.width) / 2.0
            let y = screenRect.origin.y + (screenRect.height - panelSize.height) * 0.72
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func hide() {
        panel?.orderOut(nil)
    }
    
    deinit {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}


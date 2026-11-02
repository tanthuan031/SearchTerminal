import Foundation
import Combine
import Cocoa

public class SearchViewModel: ObservableObject {
    public static let shared = SearchViewModel()
    
    @Published public var searchText: String = "" {
        didSet {
            performSearch(query: searchText)
        }
    }
    
    public enum SearchMode: String, CaseIterable, Identifiable {
        case folders = "Folders"
        case files = "Files"
        public var id: String { rawValue }
    }
    
    @Published public var searchMode: SearchMode = .folders {
        didSet { performSearch(query: searchText) }
    }
    
    @Published public var results: [SearchItem] = []
    @Published public var selectedIndex: Int = 0
    @Published public var showSettings: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Observe search text changes via Combine to guarantee every keystroke from SwiftUI binding triggers search
        $searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newQuery in
                self?.performSearch(query: newQuery)
            }
            .store(in: &cancellables)
        
        // Observe indexer changes when background indexing completes
        FolderIndexer.shared.$totalIndexedCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.performSearch(query: self.searchText)
            }
            .store(in: &cancellables)
    }
    
    public func performSearch(query: String? = nil) {
        let q = query ?? searchText
        let items = FolderIndexer.shared.search(query: q, filesOnly: searchMode == .files)
        self.results = items
        self.selectedIndex = 0
    }
    
    public var selectedItem: SearchItem? {
        guard !results.isEmpty, selectedIndex >= 0, selectedIndex < results.count else {
            return nil
        }
        return results[selectedIndex]
    }
    
    public func selectNext() {
        guard !results.isEmpty else { return }
        selectedIndex = min(selectedIndex + 1, results.count - 1)
    }
    
    public func selectPrevious() {
        guard !results.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
    }
    
    public func openTerminal(item: SearchItem? = nil) {
        guard let target = item ?? selectedItem else { return }
        AppActions.openTerminal(at: target.path)
        closePanel()
    }
    
    public func revealInFinder(item: SearchItem? = nil) {
        guard let target = item ?? selectedItem else { return }
        AppActions.revealInFinder(at: target.path)
        closePanel()
    }
    
    public func openInVSCode(item: SearchItem? = nil) {
        guard let target = item ?? selectedItem else { return }
        AppActions.openInVSCode(at: target.path)
        closePanel()
    }
    
    public func closePanel() {
        SpotlightPanelController.shared.hide()
    }
}

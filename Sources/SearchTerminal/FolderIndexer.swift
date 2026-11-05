import Foundation
import Combine

public class FolderIndexer: ObservableObject {
    public static let shared = FolderIndexer()
    
    @Published public var isIndexing: Bool = false
    @Published public var totalIndexedCount: Int = 0
    @Published public var lastIndexDuration: Double = 0.0
    
    private var allItems: [SearchItem] = []
    private let indexQueue = DispatchQueue(label: "com.searchterminal.indexer", qos: .userInitiated)
    
    private let ignoredFolderNames: Set<String> = [
        ".git", ".svn", ".hg",
        "node_modules", "Pods", "DerivedData",
        ".build", "build", "dist", "out",
        ".Trash", "Library", "Caches",
        ".vscode", ".idea", ".fleet",
        "vendor", ".venv", "venv", "env", "__pycache__",
        ".bundle", ".gradle", ".next", ".nuxt",
        ".terraform", "target", "bin", "obj"
    ]
    
    private init() {
        startIndexing()
    }
    
    private var lastIndexStart: Date = .distantPast
    
    /// Re-scan when the index is older than `maxAge` seconds, so new folders/files show up without restarting the app.
    public func refreshIfStale(maxAge: TimeInterval = 20) {
        guard !isIndexing, Date().timeIntervalSince(lastIndexStart) > maxAge else { return }
        startIndexing()
    }
    
    public func startIndexing() {
        lastIndexStart = Date()
        let paths = SettingsStore.shared.allowedPaths
        let includeFiles = true
        let maxDepth = SettingsStore.shared.maxDepth
        
        indexQueue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isIndexing = true
            }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            var collected: [SearchItem] = []
            let fm = FileManager.default
            
            for rootPath in paths {
                let expanded = (rootPath as NSString).expandingTildeInPath
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: expanded, isDirectory: &isDir), isDir.boolValue else {
                    continue
                }
                
                // Add the root folder itself
                let rootName = (expanded as NSString).lastPathComponent
                collected.append(SearchItem(
                    name: rootName,
                    path: expanded,
                    isDirectory: true,
                    lastModified: try? fm.attributesOfItem(atPath: expanded)[.modificationDate] as? Date
                ))
                
                // Traverse subfolders up to maxDepth
                self.scanDirectory(at: URL(fileURLWithPath: expanded),
                                   currentDepth: 1,
                                   maxDepth: maxDepth,
                                   includeFiles: includeFiles,
                                   collected: &collected)
            }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            DispatchQueue.main.async {
                self.allItems = collected
                self.totalIndexedCount = collected.count
                self.lastIndexDuration = duration
                self.isIndexing = false
                print("Indexing complete: \(collected.count) items in \(String(format: "%.2f", duration))s")
            }
        }
    }
    
    private func scanDirectory(at url: URL,
                              currentDepth: Int,
                              maxDepth: Int,
                              includeFiles: Bool,
                              collected: inout [SearchItem]) {
        guard currentDepth <= maxDepth else { return }
        
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .nameKey, .contentModificationDateKey]
        
        guard let contents = try? fm.contentsOfDirectory(at: url,
                                                        includingPropertiesForKeys: keys,
                                                        options: [.skipsHiddenFiles]) else {
            return
        }
        
        for fileURL in contents {
            let itemName = fileURL.lastPathComponent
            
            if ignoredFolderNames.contains(itemName) {
                continue
            }
            
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)),
                  let isDirectory = resourceValues.isDirectory else {
                continue
            }
            
            if isDirectory {
                collected.append(SearchItem(
                    name: itemName,
                    path: fileURL.path,
                    isDirectory: true,
                    lastModified: resourceValues.contentModificationDate
                ))
                
                scanDirectory(at: fileURL,
                              currentDepth: currentDepth + 1,
                              maxDepth: maxDepth,
                              includeFiles: includeFiles,
                              collected: &collected)
            } else if includeFiles {
                collected.append(SearchItem(
                    name: itemName,
                    path: fileURL.path,
                    isDirectory: false,
                    lastModified: resourceValues.contentModificationDate
                ))
            }
        }
    }
    
    public func search(query: String, filesOnly: Bool = false, limit: Int = 40) -> [SearchItem] {
        let pool = allItems.filter { $0.isDirectory != filesOnly }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: nil)
            .lowercased()
        if trimmed.isEmpty {
            // Return recently modified or root folders if query is empty
            return Array(pool.prefix(limit))
        }
        
        // Find if there are folders whose name is an exact match for the query
        let exactMatchPaths = Set(allItems.filter { $0.normalizedName == trimmed }.map { $0.path })
        
        let tokens = trimmed.split(separator: " ").map(String.init)
        
        var scoredItems: [(item: SearchItem, score: Int)] = []
        scoredItems.reserveCapacity(pool.count)
        
        for item in pool {
            let nameFolded = item.normalizedName
            let parentFolded = item.parentName.folding(options: .diacriticInsensitive, locale: nil).lowercased()
            let pathFolded = item.normalizedPath
            
            var score = 0
            var matched = false
            
            // 1. Exact match of folder/file name -> HIGHEST PRIORITY (#1)
            if nameFolded == trimmed {
                score += 20000
                matched = true
            }
            // 2. Direct child of an exact-matched folder (e.g. project inside ~/Documents/.../feedback/)
            else if exactMatchPaths.contains(item.parentPath) || parentFolded == trimmed {
                score += 10000
                if nameFolded.hasPrefix(trimmed) {
                    score += 3000
                } else if nameFolded.contains(trimmed) {
                    score += 1500
                }
                matched = true
            }
            // 3. Folder name starts with query (e.g. feedback-sdk-e2e)
            else if nameFolded.hasPrefix(trimmed) {
                score += 5000
                matched = true
            }
            // 4. Folder name contains query (e.g. ExampleFeedback)
            else if nameFolded.contains(trimmed) {
                score += 2000
                matched = true
            }
            // 5. Multi-token match within name (e.g. "my web" matches "my-web-app")
            else if tokens.count > 1 {
                var tokensInName = 0
                for token in tokens {
                    if nameFolded.contains(token) {
                        tokensInName += 1
                    }
                }
                if tokensInName == tokens.count {
                    score += 1200
                    matched = true
                } else {
                    // Match tokens across path (e.g. "feedback test" or "feedback/sdk")
                    var allInPath = true
                    for token in tokens {
                        if !pathFolded.contains(token) {
                            allInPath = false
                            break
                        }
                    }
                    if allInPath {
                        score += 400
                        matched = true
                    }
                }
            }
            // 6. Subsequence / fuzzy match in name
            else if isSubsequence(pattern: trimmed, in: nameFolded) {
                score += 800
                matched = true
            }
            
            guard matched else { continue }
            
            // Prefer folders over individual files
            if item.isDirectory {
                score += 50
            }
            
            // Tie-breaker: shorter names rank slightly higher
            let lengthPenalty = min(nameFolded.count, 40)
            score -= lengthPenalty
            
            scoredItems.append((item, score))
        }
        
        scoredItems.sort { (a, b) -> Bool in
            if a.score != b.score {
                return a.score > b.score
            }
            return (a.item.lastModified ?? .distantPast) > (b.item.lastModified ?? .distantPast)
        }
        
        return scoredItems.prefix(limit).map { $0.item }
    }
    
    private func isSubsequence(pattern: String, in target: String) -> Bool {
        guard pattern.count <= target.count else { return false }
        var pIdx = pattern.startIndex
        var tIdx = target.startIndex
        
        while pIdx < pattern.endIndex && tIdx < target.endIndex {
            if pattern[pIdx] == target[tIdx] {
                pIdx = pattern.index(after: pIdx)
            }
            tIdx = target.index(after: tIdx)
        }
        return pIdx == pattern.endIndex
    }
}

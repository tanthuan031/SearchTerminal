import Foundation
import Cocoa

public struct SearchItem: Identifiable, Hashable {
    public let id: String // Absolute path
    public let name: String
    public let path: String
    public let parentPath: String
    public let parentName: String
    public let isDirectory: Bool
    public let lastModified: Date?
    public let normalizedName: String
    public let normalizedPath: String
    
    public init(name: String, path: String, isDirectory: Bool, lastModified: Date? = nil) {
        self.id = path
        self.name = name
        self.path = path
        let parent = (path as NSString).deletingLastPathComponent
        self.parentPath = parent
        self.parentName = (parent as NSString).lastPathComponent
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.normalizedName = name.folding(options: .diacriticInsensitive, locale: nil).lowercased()
        self.normalizedPath = path.folding(options: .diacriticInsensitive, locale: nil).lowercased()
    }
    
    public var displayPath: String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
    
    public var parentDisplayPath: String {
        let home = NSHomeDirectory()
        if parentPath.hasPrefix(home) {
            return "~" + parentPath.dropFirst(home.count)
        }
        return parentPath
    }
}

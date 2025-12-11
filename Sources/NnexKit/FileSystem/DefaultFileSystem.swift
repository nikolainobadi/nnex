//
//  DefaultFileSystem.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import Files
import Foundation

public struct DefaultFileSystem {
    private let fileManager: FileManager
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
}


// MARK: - FileSystem
extension DefaultFileSystem: FileSystem {
    public var homeDirectory: any Directory {
        return FilesDirectoryAdapter(folder: Folder.home)
    }
    
    public var currentDirectory: any Directory {
        return FilesDirectoryAdapter(folder: Folder.current)
    }
    
    public func directory(at path: String) throws -> any Directory {
        return try FilesDirectoryAdapter(folder: Folder(path: path))
    }
    
    public func desktopDirectory() throws -> any Directory {
        let desktopPath = fileManager.homeDirectoryForCurrentUser.appending(path: "Desktop").path()
        return try directory(at: desktopPath)
    }

    public func readFile(at path: String) throws -> String {
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    public func writeFile(at path: String, contents: String) throws {
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    public func moveToTrash(at path: String) throws {
        try fileManager.trashItem(at: .init(fileURLWithPath: path), resultingItemURL: nil)
    }
}


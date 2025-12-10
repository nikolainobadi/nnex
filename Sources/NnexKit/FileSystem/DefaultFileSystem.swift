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
    
    public func directory(at path: String) throws -> any Directory {
        return try FilesDirectoryAdapter(folder: Folder(path: path))
    }
    
    public func desktopDirectory() throws -> any Directory {
        return try directory(at: fileManager.homeDirectoryForCurrentUser.path())
    }
}

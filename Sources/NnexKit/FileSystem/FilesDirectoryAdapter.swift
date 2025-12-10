//
//  FilesDirectoryAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import Files

public struct FilesDirectoryAdapter {
    private let folder: Folder

    public init(folder: Folder) {
        self.folder = folder
    }
}


// MARK: - Directory
extension FilesDirectoryAdapter: Directory {
    public var path: String {
        return folder.path
    }

    public var name: String {
        return folder.name
    }

    public var `extension`: String? {
        return folder.extension
    }

    public var subdirectories: [any Directory] {
        return folder.subfolders.map(FilesDirectoryAdapter.init)
    }

    public func containsFile(named name: String) -> Bool {
        return folder.containsFile(named: name)
    }

    public func subdirectory(named name: String) throws -> any Directory {
        return try FilesDirectoryAdapter(folder: folder.subfolder(named: name))
    }

    public func createSubdirectory(named name: String) throws -> any Directory {
        if let existing = try? folder.subfolder(named: name) {
            return FilesDirectoryAdapter(folder: existing)
        }

        return try FilesDirectoryAdapter(folder: folder.createSubfolder(named: name))
    }

    public func move(to parent: any Directory) throws {
        guard let destination = (parent as? FilesDirectoryAdapter)?.folder else {
            throw FileSystemError.incompatibleDirectory
        }

        try folder.move(to: destination)
    }
}


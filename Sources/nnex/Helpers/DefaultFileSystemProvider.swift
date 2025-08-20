//
//  DefaultFileSystemProvider.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/20/25.
//

import Files

struct DefaultFileSystemProvider: FileSystemProvider {
    func createFile(in folderPath: String, named: String) throws -> FileProtocol {
        let folder = try Folder(path: folderPath)
        let file = try folder.createFile(named: named)
        file.open()
        return FileWrapper(file: file)
    }
}

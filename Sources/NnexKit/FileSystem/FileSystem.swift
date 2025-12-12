//
//  FileSystem.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

public protocol FileSystem {
    var homeDirectory: any Directory { get }
    var currentDirectory: any Directory { get }

    func moveToTrash(at path: String) throws
    func directory(at path: String) throws -> any Directory
    func desktopDirectory() throws -> any Directory
    func readFile(at path: String) throws -> String
    func writeFile(at path: String, contents: String) throws
}


// MARK: - Helpers
public extension FileSystem {
    func getDirectoryAtPathOrCurrent(path: String?) throws -> any Directory {
        guard let path else {
            return currentDirectory
        }
        
        return try directory(at: path)
    }
}

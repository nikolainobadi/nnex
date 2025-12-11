//
//  FileSystem.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

public protocol FileSystem {
    var homeDirectory: any Directory { get }

    func directory(at path: String) throws -> any Directory
    func desktopDirectory() throws -> any Directory
    func readFile(at path: String) throws -> String
    func writeFile(at path: String, contents: String) throws
}

//
//  Directory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

public protocol Directory {
    var path: String { get }
    var name: String { get }
    var `extension`: String? { get }
    var subdirectories: [any Directory] { get }

    func move(to parent: any Directory) throws
    func containsFile(named name: String) -> Bool
    func subdirectory(named name: String) throws -> any Directory
    func createSubdirectory(named name: String) throws -> any Directory
    func createSubfolderIfNeeded(named name: String) throws -> any Directory
    func deleteFile(named name: String) throws
    func createFile(named name: String, contents: String) throws -> String
}

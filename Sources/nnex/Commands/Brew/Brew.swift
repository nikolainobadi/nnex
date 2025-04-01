//
//  Brew.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import Files
import ArgumentParser

extension Nnex {
    struct Brew: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Commands to manage Homebrew distribution",
            subcommands: [Publish.self, ImportTap.self, CreateTap.self, TapList.self, Untap.self, RemoveFormula.self]
        )
    }
}


// MARK: - Helper Methods
extension Nnex.Brew {
    /// Retrieves the project folder from the specified path.
    /// - Parameter path: The file path to the project folder.
    /// - Returns: The folder at the specified path, or the current folder if no path is provided.
    /// - Throws: An error if the folder cannot be found or accessed.
    static func getProjectFolder(at path: String?) throws -> Folder {
        if let path {
            return try Folder(path: path)
        }
        
        return Folder.current
    }
}

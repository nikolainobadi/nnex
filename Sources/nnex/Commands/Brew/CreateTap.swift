//
//  CreateTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import ArgumentParser

extension Nnex.Brew {
    struct CreateTap: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Registers a new homebrew tap.")
        
        @Option(name: .shortAndLong, help: "The name of the new Homebrew Tap")
        var name: String?
        
        @Option(name: .shortAndLong, help: "Details about the Homebrew Tap to include when uploading to GitHub.")
        var details: String?
        
        @Flag(name: .customLong("private"), help: "Set the repository visibility to private.")
        var isPrivate: Bool = false
        
        func run() throws {
            let context = try Nnex.makeContext()
            let parentPath = context.loadTapListFolderPath()
            
            try Nnex.makeHomebrewTapController(context: context).createNewTap(name: name, details: details, parentPath: parentPath, isPrivate: isPrivate)
        }
    }
}

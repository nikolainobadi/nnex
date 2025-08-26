//
//  CreateTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import GitShellKit
import ArgumentParser

extension Nnex.Brew {
    struct CreateTap: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Registers a new homebrew tap.")
        
        @Option(name: .shortAndLong, help: "The name of the new Homebrew Tap")
        var name: String?
        
        @Option(name: .shortAndLong, help: "Details about the Homebrew Tap to include when uploading to GitHub.")
        var details: String?
        
        @Flag(help: "Specify the repository visibility: --public (default) or --private.")
        var visibility: RepoVisibility = .publicRepo
        
        func run() throws {
            let shell = Nnex.makeShell()
            let picker = Nnex.makePicker()
            let gitHandler = Nnex.makeGitHandler()
            let context = try Nnex.makeContext()
            let manager = CreateTapExecutionManager(
                shell: shell,
                picker: picker,
                gitHandler: gitHandler,
                context: context
            )
            
            try manager.executeCreateTap(
                name: name,
                details: details,
                visibility: visibility
            )
        }
    }
}


// MARK: - Extension Dependencies
extension RepoVisibility: @retroactive EnumerableFlag {
    public static func name(for value: RepoVisibility) -> NameSpecification {
        switch value {
        case .publicRepo:
            return .customLong("public")
        case .privateRepo:
            return .customLong("private")
        }
    }
}

//
//  Nnex.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import ArgumentParser

@main
struct Nnex: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Utility to manage swift command line tools and streamline distrubution with Homebrew.",
        version: "1.1.0",
        subcommands: [
            Brew.self,
            Build.self,
            Config.self
        ]
    )
    
    nonisolated(unsafe) static var contextFactory: ContextFactory = DefaultContextFactory()
}


// MARK: - Essential Factory Methods
extension Nnex {
    static func makeShell() -> any NnexShell {
        return contextFactory.makeShell()
    }
    
    static func makePicker() -> any NnexPicker {
        return contextFactory.makePicker()
    }
    
    static func makeGitHandler() -> GitHandler {
        return contextFactory.makeGitHandler()
    }
    
    static func makeFileSystem() -> any FileSystem {
        return contextFactory.makeFileSystem()
    }
    
    static func makeContext() throws -> NnexContext {
        return try contextFactory.makeContext()
    }
    
    static func makeFolderBrowser(picker: any NnexPicker, fileSystem: any FileSystem) -> any DirectoryBrowser {
        return contextFactory.makeFolderBrowser(picker: picker, fileSystem: fileSystem)
    }
}


// MARK: - Dependencies
protocol ContextFactory {
    func makeShell() -> any NnexShell
    func makePicker() -> any NnexPicker
    func makeGitHandler() -> any GitHandler
    func makeFileSystem() -> any FileSystem
    func makeContext() throws -> NnexContext
    func makeFolderBrowser(picker: any NnexPicker, fileSystem: any FileSystem) -> any DirectoryBrowser
}

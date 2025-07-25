// The Swift Programming Language
// https://docs.swift.org/swift-book

import NnexKit
import ArgumentParser

@main
struct Nnex: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Utility to manage swift command line tools and streamline distrubution with Homebrew.",
        version: "0.8.2",
        subcommands: [Brew.self, Build.self, Config.self]
    )
    
    nonisolated(unsafe) static var contextFactory: ContextFactory = DefaultContextFactory()
}


// MARK: - Factory Methods
extension Nnex {
    static func makeShell() -> Shell {
        return contextFactory.makeShell()
    }
    
    static func makePicker() -> Picker {
        return contextFactory.makePicker()
    }
    
    static func makeContext() throws -> NnexContext {
        return try contextFactory.makeContext()
    }
    
    static func makeGitHandler() -> GitHandler {
        return contextFactory.makeGitHandler()
    }
}

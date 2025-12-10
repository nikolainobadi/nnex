// The Swift Programming Language
// https://docs.swift.org/swift-book

import NnexKit
import ArgumentParser

@main
struct Nnex: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Utility to manage swift command line tools and streamline distrubution with Homebrew.",
        version: "v1.0.0",
        subcommands: [
            Brew.self,
            Config.self,
            Archive.self,
            BuildBinary.self,
//            Export.self
        ]
    )
    
    nonisolated(unsafe) static var contextFactory: ContextFactory = DefaultContextFactory()
}


// MARK: - Factory Methods
extension Nnex {
    static func makeShell() -> any NnexShell {
        return contextFactory.makeShell()
    }
    
    static func makePicker() -> any NnexPicker {
        return contextFactory.makePicker()
    }
    
    static func makeContext() throws -> NnexContext {
        return try contextFactory.makeContext()
    }

    static func makeFileSystem() -> any FileSystem {
        return contextFactory.makeFileSystem()
    }

    static func makeGitHandler() -> GitHandler {
        return contextFactory.makeGitHandler()
    }
    
    static func makeProjectDetector() -> ProjectDetector {
        return contextFactory.makeProjectDetector()
    }
    
    static func makeMacOSArchiveBuilder() -> ArchiveBuilder {
        return contextFactory.makeMacOSArchiveBuilder()
    }
    
    static func makeNotarizeHandler() -> NotarizeHandler {
        return contextFactory.makeNotarizeHandler()
    }
    
    static func makeExportHandler() -> ExportHandler {
        return contextFactory.makeExportHandler()
    }
    
    static func makeTrashHandler() -> TrashHandler {
        return contextFactory.makeTrashHandler()
    }
}

// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser

@main
struct Nnex: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Utility to manage swift command line tools and streamline distrubution with Homebrew.",
        subcommands: [Brew.self]
    )
    
    nonisolated(unsafe) static var contextFactory: ContextFactory = DefaultContextFactory()
}


// MARK: - Factory Methods
extension Nnex {
    static func makePicker() -> Picker {
        return contextFactory.makePicker()
    }
    
    static func makeContext() throws -> SharedContext {
        return try contextFactory.makeContext()
    }
}


// MARK: - Brew
extension Nnex {
    struct Brew: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Commands to manage Homebrew distribution",
            usage: "",
            subcommands: [CreateTap.self, TapList.self]
        )
    }
}

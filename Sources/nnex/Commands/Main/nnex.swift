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
    static func makeShell() -> Shell {
        return contextFactory.makeShell()
    }
    
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
            subcommands: [ImportTap.self, CreateTap.self, TapList.self, Publish.self, Untap.self]
        )
    }
}

// MARK: - Config
extension Nnex {
    struct Config: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Commands to set preferences",
            subcommands: []
        )
    }
}

extension Nnex.Config {
    struct SetTapFolder: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Sets the path the the folder where new taps will be created"
        )
        
        @Option(name: .shortAndLong, help: "")
        var path: String?
        
        func run() throws {
//            let path = try path ?? Nnex.makePicker().getRequiredInput(prompt: "Enter the path to the folder where you want new taps to be created.")
//            let context = try Nnex.makeContext()
            
            
        }
    }
}

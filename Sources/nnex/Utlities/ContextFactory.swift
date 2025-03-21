//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files

protocol ContextFactory {
    func makeShell() -> Shell
    func makePicker() -> Picker
    func makeGitHandler() -> GitHandler
    func makeContext() throws -> SharedContext
}

// MARK: - Default Factory
struct DefaultContextFactory: ContextFactory {
    func makeShell() -> any Shell {
        return DefaultShell()
    }
    
    func makePicker() -> any Picker {
        return DefaultPicker()
    }
    
    func makeGitHandler() -> any GitHandler {
        return DefaultGitHandler(shell: makeShell(), picker: makePicker())
    }
    
    func makeContext() throws -> SharedContext {
        return try SharedContext()
    }
}

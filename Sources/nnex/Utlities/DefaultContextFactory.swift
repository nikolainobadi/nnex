//
//  DefaultContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import Files
import NnexKit

struct DefaultContextFactory: ContextFactory {
    func makeShell() -> any Shell {
        return DefaultShell()
    }
    
    func makePicker() -> any Picker {
        return DefaultPicker()
    }
    
    func makeGitHandler() -> any GitHandler {
        return DefaultGitHandler(shell: makeShell())
    }
    
    func makeContext() throws -> NnexContext {
        return try NnexContext()
    }
}

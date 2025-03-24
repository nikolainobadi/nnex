//
//  DefaultContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import Files
import NnexKit
import Foundation

//let APP_GROUP_ID = "your app group id"

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
        return try .init(appGroupId: APP_GROUP_ID)
    }
}

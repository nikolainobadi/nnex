//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit

protocol ContextFactory {
    func makeShell() -> Shell
    func makePicker() -> Picker
    func makeGitHandler() -> GitHandler
    func makeContext() throws -> NnexContext
}

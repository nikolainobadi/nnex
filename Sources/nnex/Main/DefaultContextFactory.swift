//
//  DefaultContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import NnexKit
import Foundation
import SwiftPickerKit

struct DefaultContextFactory: ContextFactory {
    func makeShell() -> any NnexShell {
        return DefaultShell()
    }

    func makePicker() -> any NnexPicker {
        return SwiftPicker()
    }

    func makeGitHandler() -> any GitHandler {
        return DefaultGitHandler(shell: makeShell())
    }
    
    func makeFileSystem() -> any FileSystem {
        return DefaultFileSystem()
    }

    func makeContext() throws -> NnexContext {
        return try .init()
    }
    
    func makeFolderBrowser(picker: any NnexPicker, fileSystem: any FileSystem) -> any DirectoryBrowser {
        return DefaultDirectoryBrowser(picker: picker, fileSystem: fileSystem, homeDirectoryURL: FileManager.default.homeDirectoryForCurrentUser)
    }
}

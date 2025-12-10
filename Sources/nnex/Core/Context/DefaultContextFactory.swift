//
//  DefaultContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import NnexKit
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

    func makeContext() throws -> NnexContext {
        return try .init()
    }

    func makeFileSystem() -> any FileSystem {
        return DefaultFileSystem()
    }

    func makeProjectDetector() -> any ProjectDetector {
        return DefaultProjectDetector(shell: makeShell())
    }
    
    func makeMacOSArchiveBuilder() -> any ArchiveBuilder {
        return DefaultMacOSArchiveBuilder(shell: makeShell())
    }
    
    func makeNotarizeHandler() -> any NotarizeHandler {
        return DefaultNotarizeHandler(shell: makeShell(), picker: makePicker())
    }
    
    func makeExportHandler() -> any ExportHandler {
        return DefaultExportHandler(shell: makeShell())
    }
    
    func makeTrashHandler() -> any TrashHandler {
        return DefaultTrashHandler()
    }
}

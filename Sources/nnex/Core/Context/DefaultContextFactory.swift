//
//  DefaultContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import NnexKit

let APP_GROUP_ID = "R8SJ24LQF3.com.nobadi.nnex"

struct DefaultContextFactory: ContextFactory {
    func makeShell() -> any NnexShell {
        return DefaultShell()
    }

    func makePicker() -> any NnexPicker {
        return DefaultPicker()
    }

    func makeGitHandler() -> any GitHandler {
        return DefaultGitHandler(shell: makeShell())
    }

    func makeContext() throws -> NnexContext {
        return try .init(appGroupId: APP_GROUP_ID)
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

//
//  DefaultContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import NnexKit

/// enter your own app group id here
let APP_GROUP_ID = "R8SJ24LQF3.com.nobadi.nnex"

/// Default implementation of the ContextFactory protocol.
struct DefaultContextFactory: ContextFactory {
    /// Creates a default shell instance.
    /// - Returns: A DefaultShell instance.
    func makeShell() -> any Shell {
        return DefaultShell()
    }

    /// Creates a default picker instance.
    /// - Returns: A DefaultPicker instance.
    func makePicker() -> any NnexPicker {
        return DefaultPicker()
    }

    /// Creates a default Git handler instance.
    /// - Returns: A DefaultGitHandler instance.
    func makeGitHandler() -> any GitHandler {
        return DefaultGitHandler(shell: makeShell())
    }

    /// Creates a default Nnex context instance.
    /// - Returns: A NnexContext instance.
    /// - Throws: An error if the context could not be created.
    func makeContext() throws -> NnexContext {
        return try .init(appGroupId: APP_GROUP_ID)
    }
    
    /// Creates a default project detector instance.
    /// - Returns: A DefaultProjectDetector instance.
    func makeProjectDetector() -> ProjectDetector {
        return DefaultProjectDetector(shell: makeShell())
    }
    
    /// Creates a default macOS archive builder instance.
    /// - Returns: A DefaultMacOSArchiveBuilder instance.
    func makeMacOSArchiveBuilder() -> ArchiveBuilder {
        return DefaultMacOSArchiveBuilder(shell: makeShell())
    }
    
    /// Creates a default notarize handler instance.
    /// - Returns: A DefaultNotarizeHandler instance.
    func makeNotarizeHandler() -> NotarizeHandler {
        return DefaultNotarizeHandler(shell: makeShell(), picker: makePicker())
    }
    
    /// Creates a default export handler instance.
    /// - Returns: A DefaultExportHandler instance.
    func makeExportHandler() -> ExportHandler {
        return DefaultExportHandler(shell: makeShell())
    }
}

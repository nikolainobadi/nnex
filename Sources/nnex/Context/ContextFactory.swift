//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import NnShellKit

/// Factory for creating context-related objects.
protocol ContextFactory {
    /// Creates a new shell instance.
    /// - Returns: A Shell instance.
    func makeShell() -> any Shell

    /// Creates a new picker instance.
    /// - Returns: A NnexPicker instance.
    func makePicker() -> NnexPicker

    /// Creates a new Git handler instance.
    /// - Returns: A GitHandler instance.
    func makeGitHandler() -> GitHandler

    /// Creates a new Nnex context.
    /// - Returns: An NnexContext instance.
    /// - Throws: An error if the context could not be created.
    func makeContext() throws -> NnexContext
    
    /// Creates a new project detector instance.
    /// - Returns: A ProjectDetector instance.
    func makeProjectDetector() -> ProjectDetector
    
    /// Creates a new macOS archive builder instance.
    /// - Returns: An ArchiveBuilder instance.
    func makeMacOSArchiveBuilder() -> ArchiveBuilder
    
    /// Creates a new notarize handler instance.
    /// - Returns: A NotarizeHandler instance.
    func makeNotarizeHandler() -> NotarizeHandler
    
    /// Creates a new export handler instance.
    /// - Returns: An ExportHandler instance.
    func makeExportHandler() -> ExportHandler
    
    /// Creates a new trash handler instance.
    /// - Returns: A TrashHandler instance.
    func makeTrashHandler() -> TrashHandler
}

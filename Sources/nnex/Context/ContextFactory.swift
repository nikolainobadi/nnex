//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit

/// Factory for creating context-related objects.
protocol ContextFactory {
    /// Creates a new shell instance.
    /// - Returns: A Shell instance.
    func makeShell() -> Shell

    /// Creates a new picker instance.
    /// - Returns: A Picker instance.
    func makePicker() -> Picker

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
}

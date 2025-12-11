//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit

protocol ContextFactory {
    func makeShell() -> any NnexShell
    func makePicker() -> any NnexPicker
    func makeGitHandler() -> any GitHandler
    func makeContext() throws -> NnexContext
    func makeFileSystem() -> any FileSystem
    func makeTrashHandler() -> any TrashHandler
    func makeExportHandler() -> any ExportHandler
    func makeNotarizeHandler() -> any NotarizeHandler
    func makeProjectDetector() -> any ProjectDetector
    func makeMacOSArchiveBuilder() -> any ArchiveBuilder
    func makeFolderBrowser(picker: any NnexPicker, fileSystem: any FileSystem) -> any DirectoryBrowser
}

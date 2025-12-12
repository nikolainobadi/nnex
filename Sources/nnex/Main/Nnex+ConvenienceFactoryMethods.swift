//
//  Nnex+ConvenienceFactoryMethods.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import NnexKit

extension Nnex {
    static func makeHomebrewTapController(context: NnexContext? = nil) throws -> HomebrewTapController {
        let shell = makeShell()
        let picker = makePicker()
        let gitHandler = makeGitHandler()
        let context = try context ?? makeContext()
        let fileSystem = makeFileSystem()
        let folderBrowser = makeFolderBrowser(picker: picker, fileSystem: fileSystem)
        let store = HomebrewTapStoreAdapter(context: context)
        let manager = HomebrewTapManager(shell: shell, store: store, gitHandler: gitHandler)
        
        return .init(picker: picker, fileSystem: fileSystem, service: manager, folderBrowser: folderBrowser)
    }
    
    static func makeHomebrewFormulaController(context: NnexContext? = nil) throws -> HomebrewFormulaController {
        let picker = makePicker()
        let fileSystem = makeFileSystem()
        let context = try context ?? makeContext()
        let store = HomebrewFormulaStoreAdapter(context: context)
        let manager = HomebrewFormulaManager(store: store)
        
        return .init(picker: picker, fileSystem: fileSystem, service: manager)
    }
}

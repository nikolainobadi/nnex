//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files

protocol ContextFactory {
    func makeShell() -> Shell
    func makePicker() -> Picker
    func makeFolderLoader() -> FolderLoader
    func makeContext() throws -> SharedContext
}

// MARK: - Default Factory
struct DefaultContextFactory: ContextFactory {
    func makeShell() -> any Shell {
        return DefaultShell()
    }
    
    func makePicker() -> any Picker {
        return DefaultPicker()
    }
    
    func makeFolderLoader() -> any FolderLoader {
        return DefaultFolderLoader()
    }
    
    func makeContext() throws -> SharedContext {
        return try SharedContext()
    }
}


// TODO: - 
struct DefaultFolderLoader: FolderLoader {
    func loadTapListFolder() throws -> Folder {
        return try Folder.home.subfolder(named: "Desktop")
    }
}

protocol FolderLoader {
    func loadTapListFolder() throws -> Folder
}

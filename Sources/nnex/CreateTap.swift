//
//  Tap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import ArgumentParser

extension Nnex.Brew {
    struct CreateTap: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Registers a new homebrew tap."
        )
        
        @Option(name: .shortAndLong, help: "")
        var name: String?
        
        func run() throws {
            let context = try Nnex.makeContext()
            let name = try getTapName(name: name)
            let folderLoader = Nnex.contextFactory.makeFolderLoader()
            
            // TODO: - maybe ask for location of new tap, or choose a default location
            // perhaps this could be a configuration that can be adjusted
            // first time should ask user for path or allow them to select pre-defined default path
            let parentFolder = try folderLoader.loadTapListFolder()
            let tapFolder = try parentFolder.createSubfolderIfNeeded(withName: name.homebrewTapName)
            
            print("Created folder for new tap named \(name) at \(tapFolder.path)")
            
            // TODO: - need to upload to GitHub
            
            let newTap = SwiftDataTap(name: name, localPath: tapFolder.path, remotePath: "")
            
            try context.saveNewTap(newTap)
        }
    }
}


// MARK: - Private Methods
fileprivate extension Nnex.Brew.CreateTap {
    func getTapName(name: String?) throws -> String {
        if let name, !name.isEmpty {
            return name
        }
        
        let picker = Nnex.makePicker()
        let name = try picker.getRequiredInput(.newTap)
        
        if name.isEmpty {
            throw PickerError.invalidName
        }
        
        return name
    }
}

enum PickerError: Error {
    case invalidName
    case noSavedTaps
}

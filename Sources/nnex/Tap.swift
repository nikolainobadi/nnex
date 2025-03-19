//
//  Tap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import SwiftPicker
import ArgumentParser

extension Nnex.Brew {
    struct Tap: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Registers a new homebrew tap."
        )
        
        func run() throws {
            let context = try Nnex.makeContext()
            let name = try getTapName()
            
            // TODO: - maybe ask for location of new tap, or choose a default location
            // perhaps this could be a configuration that can be adjusted
            // first time should ask user for path or allow them to select pre-defined default path
            let parentFolder = try Folder.home.subfolder(named: "Desktop")
            let tapFolder = try parentFolder.createSubfolderIfNeeded(withName: name)
            
            print("Created folder for new tap named \(name) at \(tapFolder.path)")
            
            // TODO: - need to upload to GitHub
            let newTap = SwiftDataTap(name: name, localPath: tapFolder.path, remotePath: "")
            
            try context.saveNewTap(newTap)
        }
    }
}


// MARK: - Private Methods
fileprivate extension Nnex.Brew.Tap {
    func getTapName() throws -> String {
        let picker = Nnex.makePicker()
        var name = try picker.getRequiredInput("Enter the name of your new Homebrew Tap.")
        
        if !name.lowercased().contains("homebrew-") {
            name = "homebrew-\(name)"
        }
        
        return name
    }
}

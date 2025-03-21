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
            let tapListFolder = try getTapListFolder()
            let homebrewTapName = name.homebrewTapName
            let tapFolder = try tapListFolder.createSubfolder(named: homebrewTapName)
            
            // TODO: - 
            print("Created folder for new tap named \(name) at \(tapFolder.path)")
            
            let remotePath = try createNewRepository(name: homebrewTapName, path: tapFolder.path)
            
            let newTap = SwiftDataTap(name: name, localPath: tapFolder.path, remotePath: remotePath)
            
            try context.saveNewTap(newTap)
        }
    }
}


// MARK: - Private Methods
fileprivate extension Nnex.Brew.CreateTap {
    func getTapListFolder() throws -> Folder {
        fatalError()
    }
    
    func createNewRepository(name: String, path: String) throws -> String {
        let visibility = ""
        let details = ""
        
        let shell = Nnex.makeShell()
        let gitHandler = GitHandler(shell: shell)
        
        // TODO: - neec to create new local git repo
        try gitHandler.createNewRepo(name: name, visibility: visibility, details: details, path: path)
        
        return try gitHandler.getRemoteURL(path: path)
    }
    
    func getTapName(name: String?) throws -> String {
        if let name, !name.isEmpty {
            return name
        }
        
        let picker = Nnex.makePicker()
        let name = try picker.getRequiredInput(prompt: "Enter the name of your new Homebrew Tap.")
        
        if name.isEmpty {
            throw PickerError.invalidName
        }
        
        return name
    }
}

enum PickerError: Error {
    case invalidName
    case noSavedTaps
    case noTapRegisterdForProject
}

enum VersionError: Error {
    case noPreviousVersion
    case invalidVersionNumber
}

enum NnexError: Error {
    case missingTap
    case missingSha256
    case shellCommandFailed
}

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
            let tapListFolder = try getTapListFolder(context: context)
            let homebrewTapName = name.homebrewTapName
            let tapFolder = try tapListFolder.createSubfolder(named: homebrewTapName)
            
            print("Created folder for new tap named \(name) at \(tapFolder.path)")
            
            let remotePath = try createNewRepository(name: homebrewTapName, path: tapFolder.path)
            let newTap = SwiftDataTap(name: name, localPath: tapFolder.path, remotePath: remotePath)
            
            try context.saveNewTap(newTap)
        }
    }
}


// MARK: - Private Methods
fileprivate extension Nnex.Brew.CreateTap {
    func getTapListFolder(context: SharedContext) throws -> Folder {
        if let path = context.loadTapListFolderPath() {
            return try Folder(path: path)
        }
        
        let picker = Nnex.makePicker()
        let homeFolder = Folder.home
        let addNewPath = "SET CUSTOM PATH"
        let defaultTapFolderName = "NnexHomebrewTaps"
        let defaultPath = homeFolder.path + defaultTapFolderName
        let prompt = "Missing Taplist folder path. Where would you like new Homebrew Taps to be created?"
        let selection = try picker.requiredSingleSelection(title: prompt, items: [addNewPath, defaultPath])
        
        var tapListFolder: Folder
        
        if selection == addNewPath {
            let newPath = try picker.getRequiredInput(prompt: "Enter the path where you Homebrew Taps should be created.")
            tapListFolder = try Folder(path: newPath)
        } else {
            tapListFolder = try homeFolder.createSubfolder(named: defaultTapFolderName)
        }
        
        print("Created Homebrew Taplist folder at \(tapListFolder.path)")
        context.saveTapListFolderPath(path: tapListFolder.path)
        print("Saved path for Taplist folder")
        return tapListFolder
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

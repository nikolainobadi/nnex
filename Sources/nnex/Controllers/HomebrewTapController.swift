//
//  HomebrewTapController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

import NnexKit

struct HomebrewTapController {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let folderBrowser: any DirectoryBrowser
    private let service: any HomebrewTapService
}


// MARK: - Create
extension HomebrewTapController {
    func createNewTap(name: String?, details: String?, parentPath: String?, isPrivate: Bool) throws {
        let name = try selectTapName(name: name)
        let details = try details ?? picker.getRequiredInput(prompt: "Enter the details for this new tap.")
        let parentFolder = try selectParentFolder(parentPath: parentPath)
        
        try service.createNewTap(named: name, details: details, in: parentFolder)
    }
}


// MARK: - Private Methods
private extension HomebrewTapController {
    func selectTapName(name: String?) throws -> String {
        if let name, !name.isEmpty {
            return name
        }

        let name = try picker.getRequiredInput(prompt: "Enter the name of your new Homebrew Tap.")

        if name.isEmpty {
            throw NnexError.invalidTapName
        }

        return name
    }
    
    func selectParentFolder(parentPath: String?) throws -> any Directory {
        if let parentPath {
            return try fileSystem.directory(at: parentPath)
        }
        
        let addNewPath = "SET CUSTOM PATH"
        let defaultTapListFolderName = "NnexHomebrewTaps"
        let defaultPath = fileSystem.homeDirectory.path.appendingPathComponent(defaultTapListFolderName)
        let prompt = "Missing Taplist folder path. Where would you like new Homebrew Taps to be created?"
        let selection = try picker.requiredSingleSelection(prompt, items: [addNewPath, defaultPath])
        
        var tapListFolder: any Directory
        
        if selection == addNewPath {
            tapListFolder = try folderBrowser.browseForDirectory(prompt: "Select the fodler where your Homebrew Taps should be created.")
        } else {
            tapListFolder = try fileSystem.homeDirectory.createSubfolderIfNeeded(named: defaultTapListFolderName)
        }
        
        // TODO: - save tapListFolderPath in defaults?
        
        return tapListFolder
    }
}


// MARK: - Dependencies
protocol HomebrewTapService {
    func createNewTap(named name: String, details: String, in parentFolder: any Directory) throws
}

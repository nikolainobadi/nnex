//
//  CreateTapManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import NnexKit
import GitShellKit
import Foundation

struct CreateTapManager {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let folderBrowser: any DirectoryBrowser
    private let context: NnexContext
    
    init(
        shell: any NnexShell,
        picker: any NnexPicker,
        gitHandler: any GitHandler,
        fileSystem: any FileSystem,
        folderBrowser: any DirectoryBrowser,
        context: NnexContext
    ) {
        self.shell = shell
        self.picker = picker
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
        self.folderBrowser = folderBrowser
        self.context = context
    }
}


// MARK: - Action
extension CreateTapManager {
    func executeCreateTap(name: String?, details: String?, visibility: RepoVisibility) throws {
        try gitHandler.ghVerification()
        
        let tapName = try getTapName(name: name)
        let tapListFolder = try getTapListFolder()
        let homebrewTapName = tapName.homebrewTapName
        let tapFolder = try tapListFolder.createSubfolderIfNeeded(named: homebrewTapName)
        _ = try tapFolder.createSubfolderIfNeeded(named: "Formula")

        print("Created folder for new tap named \(tapName) at \(tapFolder.path)")
        
        let projectDetails = try details ?? picker.getRequiredInput(prompt: "Enter the details for this new tap")
        let remotePath = try createNewRepository(
            tapName: homebrewTapName,
            path: tapFolder.path,
            projectDetails: projectDetails,
            visibility: visibility
        )
        
        let newTap = SwiftDataHomebrewTap(name: tapName, localPath: tapFolder.path, remotePath: remotePath)
        try context.saveNewTap(newTap)
    }
}


// MARK: - Private Methods
private extension CreateTapManager {
    /// Retrieves the name of the new tap, prompting the user if not provided.
    /// - Parameter name: The optional tap name.
    /// - Returns: The resolved tap name as a string.
    /// - Throws: An error if the name is invalid.
    func getTapName(name: String?) throws -> String {
        if let name, !name.isEmpty {
            return name
        }

        let name = try picker.getRequiredInput(prompt: "Enter the name of your new Homebrew Tap.")

        if name.isEmpty {
            throw NnexError.invalidTapName
        }

        return name
    }

    /// Creates a new GitHub repository for the tap.
    /// - Parameters:
    ///   - tapName: The name of the tap.
    ///   - path: The local path to initialize the repository.
    ///   - projectDetails: Optional project details.
    ///   - visibility: The visibility of the repository.
    /// - Returns: The remote URL of the created repository.
    /// - Throws: An error if the repository creation fails.
    func createNewRepository(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String {
        try gitHandler.gitInit(path: path)
        print("Initialized local git repository for \(tapName)")

        let remotePath = try gitHandler.remoteRepoInit(
            tapName: tapName,
            path: path,
            projectDetails: projectDetails,
            visibility: visibility
        )

        print("Created new GitHub repository for \(tapName) at \(remotePath)")
        return remotePath
    }

    /// Retrieves the folder where new Homebrew taps will be created.
    /// - Returns: A Folder instance for storing taps.
    /// - Throws: An error if the folder cannot be accessed or created.
    func getTapListFolder() throws -> any Directory {
        if let path = context.loadTapListFolderPath() {
            return try fileSystem.directory(at: path)
        }

        let homeFolder = fileSystem.homeDirectory
        let addNewPath = "SET CUSTOM PATH"
        let defaultTapFolderName = "NnexHomebrewTaps"
        let defaultPath = homeFolder.path + defaultTapFolderName
        let prompt = "Missing Taplist folder path. Where would you like new Homebrew Taps to be created?"
        let selection = try picker.requiredSingleSelection(prompt, items: [addNewPath, defaultPath])

        var tapListFolder: any Directory
        if selection == addNewPath {
            tapListFolder = try folderBrowser.browseForDirectory(prompt: "Select the folder where your Homebrew Taps should be created")
        } else {
            tapListFolder = try homeFolder.createSubfolderIfNeeded(named: defaultTapFolderName)
        }

        print("Created Homebrew Taplist folder at \(tapListFolder.path)")
        context.saveTapListFolderPath(path: tapListFolder.path)
        print("Saved path for Taplist folder")

        return tapListFolder
    }
}

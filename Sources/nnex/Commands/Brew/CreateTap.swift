//
//  Tap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import NnexKit
import GitShellKit
import ArgumentParser

extension Nnex.Brew {
    struct CreateTap: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Registers a new homebrew tap.")
        
        @Option(name: .shortAndLong, help: "The name of the new Homebrew Tap")
        var name: String?
        
        @Option(name: .shortAndLong, help: "Details about the Homebrew Tap to include when uploading to GitHub.")
        var details: String?
        
        @Flag(help: "Specify the repository visibility: --public (default) or --private.")
        var visibility: RepoVisibility = .publicRepo
        
        func run() throws {
            try gitHandler.checkForGitHubCLI()
            
            let context = try Nnex.makeContext()
            let name = try getTapName(name: name)
            let tapListFolder = try getTapListFolder(context: context)
            let homebrewTapName = name.homebrewTapName
            let tapFolder = try tapListFolder.createSubfolder(named: homebrewTapName)
            
            print("Created folder for new tap named \(name) at \(tapFolder.path)")
            
            let remotePath = try createNewRepository(tapName: homebrewTapName, path: tapFolder.path, projectDetails: details, visibility: visibility)
            let newTap = SwiftDataTap(name: name, localPath: tapFolder.path, remotePath: remotePath)
            
            try context.saveNewTap(newTap)
        }
    }
}


// MARK: - Private Methods
fileprivate extension Nnex.Brew.CreateTap {
    /// Returns a Picker instance for user input.
    var picker: Picker {
        return Nnex.makePicker()
    }

    /// Returns a GitHandler instance for managing repository operations.
    var gitHandler: GitHandler {
        return Nnex.makeGitHandler()
    }

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
    func createNewRepository(tapName: String, path: String, projectDetails: String?, visibility: RepoVisibility) throws -> String {
        let projectDetails = try projectDetails ?? picker.getRequiredInput(prompt: "Enter the details for this new tap")
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
    /// - Parameter context: The application context.
    /// - Returns: A Folder instance for storing taps.
    /// - Throws: An error if the folder cannot be accessed or created.
    func getTapListFolder(context: NnexContext) throws -> Folder {
        if let path = context.loadTapListFolderPath() {
            return try Folder(path: path)
        }

        let homeFolder = Folder.home
        let addNewPath = "SET CUSTOM PATH"
        let defaultTapFolderName = "NnexHomebrewTaps"
        let defaultPath = homeFolder.path + defaultTapFolderName
        let prompt = "Missing Taplist folder path. Where would you like new Homebrew Taps to be created?"
        let selection = try picker.requiredSingleSelection(title: prompt, items: [addNewPath, defaultPath])

        var tapListFolder: Folder
        if selection == addNewPath {
            let newPath = try picker.getRequiredInput(prompt: "Enter the path where your Homebrew Taps should be created.")
            tapListFolder = try Folder(path: newPath)
        } else {
            tapListFolder = try homeFolder.createSubfolder(named: defaultTapFolderName)
        }

        print("Created Homebrew Taplist folder at \(tapListFolder.path)")
        context.saveTapListFolderPath(path: tapListFolder.path)
        print("Saved path for Taplist folder")

        return tapListFolder
    }
}


// MARK: - Extension Dependencies
extension RepoVisibility: @retroactive EnumerableFlag {
    public static func name(for value: RepoVisibility) -> NameSpecification {
        switch value {
        case .publicRepo:
            return .customLong("public")
        case .privateRepo:
            return .customLong("private")
        }
    }
}

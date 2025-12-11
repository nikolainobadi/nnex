//
//  PublishExecutionManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import NnexKit
import Foundation

struct PublishExecutionManager {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let folderBrowser: any DirectoryBrowser
    private let publishInfoLoader: PublishInfoLoader
    
    init(
        shell: any NnexShell,
        picker: any NnexPicker,
        gitHandler: any GitHandler,
        fileSystem: any FileSystem,
        folderBrowser: any DirectoryBrowser,
        publishInfoLoader: PublishInfoLoader
    ) {
        self.shell = shell
        self.picker = picker
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
        self.folderBrowser = folderBrowser
        self.publishInfoLoader = publishInfoLoader
    }
}


// MARK: - Action
extension PublishExecutionManager {
    func executePublish(
        projectFolder: any Directory,
        version: ReleaseVersionInfo?,
        buildType: BuildType,
        notes: String?,
        notesFile: String?,
        message: String?,
        skipTests: Bool
    ) throws {
        // TODO: - 
//        try gitHandler.checkForGitHubCLI()
//        try ensureNoUncommittedChanges(at: projectFolder.path)
//        
//        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler, shell: shell, fileSystem: fileSystem)
//        let (resolvedVersionInfo, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: version, projectPath: projectFolder.path)
//        
//        let (tap, formula, buildType) = try getTapAndFormula(projectFolder: projectFolder, buildType: buildType, skipTests: skipTests)
//        let binaryOutput = try PublishUtilities.buildBinary(formula: formula, buildType: buildType, skipTesting: skipTests, shell: shell)
//        let archivedBinaries = try PublishUtilities.createArchives(from: binaryOutput, shell: shell)
//        let (assetURLs, versionNumber) = try uploadRelease(folder: projectFolder, archivedBinaries: archivedBinaries, versionInfo: resolvedVersionInfo, previousVersion: previousVersion, releaseNotesSource: .init(notes: notes, notesFile: notesFile))
//
//        let formulaContent = try PublishUtilities.makeFormulaContent(formula: formula, version: versionNumber, archivedBinaries: archivedBinaries, assetURLs: assetURLs)
//        
//        try publishFormula(formulaContent, formulaName: formula.name, message: message, tap: tap)
    }
}


// MARK: - Private Methods
private extension PublishExecutionManager {
    /// Ensures there are no uncommitted changes in the repository at the specified path.
    /// - Parameter path: The path to the repository to check.
    /// - Throws: An error if there are uncommitted changes.
    /// - Note: This method should be moved to GitHandler in NnexKit when possible.
    func ensureNoUncommittedChanges(at path: String) throws {
        let result = try shell.bash("cd \"\(path)\" && git status --porcelain")
        
        if !result.isEmpty {
            print("""
            There are uncommitted changes in the repository at \(path.yellow):
            
            \(result)
            
            Please commit or stash your changes before publishing.
            """)
            throw PublishExecutionError.uncommittedChanges
        }
    }

    /// Retrieves the Homebrew tap and formula associated with the project folder.
    /// - Parameters:
    ///   - projectFolder: The project folder.
    ///   - buildType: The build type to use.
    ///   - skipTests: Whether to skip tests during loading.
    /// - Returns: A tuple containing the tap, formula, and build type.
    /// - Throws: An error if the tap or formula cannot be found.
    func getTapAndFormula(projectFolder: any Directory, buildType: BuildType, skipTests: Bool) throws -> (SwiftDataHomebrewTap, SwiftDataHomebrewFormula, BuildType) {
        fatalError() // TODO: - 
//        let (tap, formula) = try publishInfoLoader.loadPublishInfo()
        
        // Note: The formula's localProjectPath update is now handled by PublishInfoLoader if needed
//        return (tap, formula, buildType)
    }

    /// Uploads a release to GitHub and returns the asset URLs and version number.
    /// - Parameters:
    ///   - folder: The project folder.
    ///   - archivedBinaries: The archived binaries to upload.
    ///   - versionInfo: The version information for the release.
    ///   - previousVersion: The previous version, if any.
    ///   - releaseNotesSource: The source of release notes.
    /// - Returns: A tuple containing an array of asset URLs and the version number from the GitHub release.
    /// - Throws: An error if the upload fails.
    func uploadRelease(folder: any Directory, archivedBinaries: [ArchivedBinary], versionInfo: ReleaseVersionInfo, previousVersion: String?, releaseNotesSource: ReleaseNotesSource) throws -> (assetURLs: [String], versionNumber: String) {
        let handler = ReleaseHandler(picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, folderBrowser: folderBrowser)
        return try handler.uploadRelease(folder: folder, archivedBinaries: archivedBinaries, versionInfo: versionInfo, previousVersion: previousVersion, releaseNotesSource: releaseNotesSource)
    }

    
    /// Publishes the Homebrew formula to the specified tap.
    /// - Parameters:
    ///   - content: The formula content as a string.
    ///   - formulaName: The name of the formula.
    ///   - message: An optional commit message.
    ///   - tap: The Homebrew tap to publish to.
    /// - Throws: An error if the formula cannot be published.
    func publishFormula(_ content: String, formulaName: String, message: String?, tap: SwiftDataHomebrewTap) throws {
        let publisher = FormulaPublisher(gitHandler: gitHandler, fileSystem: fileSystem)
        let commitMessage = try getMessage(message: message)
        let formulaPath = try publisher.publishFormula(content, formulaName: formulaName, commitMessage: commitMessage, tapFolderPath: tap.localPath)

        print("\nSuccessfully created formula at \(formulaPath.yellow)")
        if commitMessage != nil {
            print("pushed \(tap.name.blue.underline) to \("GitHub".green).")
        }
    }

    /// Retrieves a commit message from the user or uses a provided message.
    /// - Parameter message: An optional commit message.
    /// - Returns: The commit message to use, or nil if not committing.
    /// - Throws: An error if the user input is invalid.
    func getMessage(message: String?) throws -> String? {
        if let message {
            return message
        }

        guard picker.getPermission(prompt: "\nWould you like to commit and push the tap to \("GitHub".green)?") else {
            return nil
        }

        return try picker.getRequiredInput(prompt: "Enter your commit message.")
    }
    
}


// MARK: - Helper Types
struct ReleaseNotesSource {
    let notes: String?
    let notesFile: String?
}

enum PublishExecutionError: Error, LocalizedError {
    case uncommittedChanges
    case noPreviousVersionToIncrement
    
    var errorDescription: String? {
        switch self {
        case .uncommittedChanges:
            return "Repository has uncommitted changes"
        case .noPreviousVersionToIncrement:
            return "No previous version found to increment"
        }
    }
}

//
//  PublishExecutionManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Files
import NnexKit
import NnShellKit
import Foundation

struct PublishExecutionManager {
    private let shell: any Shell
    private let picker: NnexPicker
    private let gitHandler: GitHandler
    private let publishInfoLoader: PublishInfoLoader
    private let trashHandler: TrashHandler
    private let aiReleaseEnabled: Bool
    
    init(shell: any Shell, picker: NnexPicker, gitHandler: GitHandler, publishInfoLoader: PublishInfoLoader, trashHandler: TrashHandler, aiReleaseEnabled: Bool) {
        self.shell = shell
        self.picker = picker
        self.gitHandler = gitHandler
        self.publishInfoLoader = publishInfoLoader
        self.trashHandler = trashHandler
        self.aiReleaseEnabled = aiReleaseEnabled
    }
}


// MARK: - Action
extension PublishExecutionManager {
    func executePublish(
        projectFolder: Folder,
        version: ReleaseVersionInfo?,
        buildType: BuildType,
        notes: String?,
        notesFile: String?,
        message: String?,
        skipTests: Bool
    ) throws {
        try gitHandler.checkForGitHubCLI()
        try ensureNoUncommittedChanges(at: projectFolder.path)
        
        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler, shell: shell)
        let (resolvedVersionInfo, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: version, projectPath: projectFolder.path)
        
        // Handle changelog update if AI release is enabled
        try handleChangelogUpdate(projectFolder: projectFolder, versionInfo: resolvedVersionInfo, previousVersion: previousVersion)
        
        let (tap, formula, buildType) = try getTapAndFormula(projectFolder: projectFolder, buildType: buildType, skipTests: skipTests)
        let binaryOutput = try PublishUtilities.buildBinary(formula: formula, buildType: buildType, skipTesting: skipTests, shell: shell)
        let archivedBinaries = try PublishUtilities.createArchives(from: binaryOutput, shell: shell)
        let assetURLs = try uploadRelease(folder: projectFolder, archivedBinaries: archivedBinaries, versionInfo: resolvedVersionInfo, previousVersion: previousVersion, releaseNotesSource: .init(notes: notes, notesFile: notesFile))
        
        let formulaContent = try PublishUtilities.makeFormulaContent(formula: formula, archivedBinaries: archivedBinaries, assetURLs: assetURLs)
        
        try publishFormula(formulaContent, formulaName: formula.name, message: message, tap: tap)
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
    func getTapAndFormula(projectFolder: Folder, buildType: BuildType, skipTests: Bool) throws -> (SwiftDataTap, SwiftDataFormula, BuildType) {
        let (tap, formula) = try publishInfoLoader.loadPublishInfo()
        
        // Note: The formula's localProjectPath update is now handled by PublishInfoLoader if needed
        return (tap, formula, buildType)
    }

    /// Uploads a release to GitHub and returns the asset URLs.
    /// - Parameters:
    ///   - folder: The project folder.
    ///   - archivedBinaries: The archived binaries to upload.
    ///   - versionInfo: The version information for the release.
    ///   - previousVersion: The previous version, if any.
    ///   - releaseNotesSource: The source of release notes.
    /// - Returns: An array of asset URLs from the GitHub release.
    /// - Throws: An error if the upload fails.
    func uploadRelease(folder: Folder, archivedBinaries: [ArchivedBinary], versionInfo: ReleaseVersionInfo, previousVersion: String?, releaseNotesSource: ReleaseNotesSource) throws -> [String] {
        let handler = ReleaseHandler(picker: picker, gitHandler: gitHandler, trashHandler: trashHandler)
        return try handler.uploadRelease(folder: folder, archivedBinaries: archivedBinaries, versionInfo: versionInfo, previousVersion: previousVersion, releaseNotesSource: releaseNotesSource)
    }

    
    /// Publishes the Homebrew formula to the specified tap.
    /// - Parameters:
    ///   - content: The formula content as a string.
    ///   - formulaName: The name of the formula.
    ///   - message: An optional commit message.
    ///   - tap: The Homebrew tap to publish to.
    /// - Throws: An error if the formula cannot be published.
    func publishFormula(_ content: String, formulaName: String, message: String?, tap: SwiftDataTap) throws {
        let publisher = FormulaPublisher(gitHandler: gitHandler)
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
    
    /// Handles changelog update/creation when AI release is enabled.
    /// - Parameters:
    ///   - projectFolder: The project folder.
    ///   - versionInfo: The resolved version information.
    ///   - previousVersion: The previous version string, if any.
    /// - Throws: An error if the changelog update fails.
    func handleChangelogUpdate(projectFolder: Folder, versionInfo: ReleaseVersionInfo, previousVersion: String?) throws {
        guard aiReleaseEnabled else { return }
        
        let changelogPath = projectFolder.path + "/CHANGELOG.md"
        let changelogExists = FileManager.default.fileExists(atPath: changelogPath)
        
        let prompt = changelogExists
            ? "Would you like to update the CHANGELOG.md for this release?"
            : "Would you like to create a CHANGELOG.md for this release?"
        
        guard picker.getPermission(prompt: prompt) else { return }
        
        // Get the actual version string
        let versionString = try getVersionString(versionInfo: versionInfo, previousVersion: previousVersion, projectPath: projectFolder.path)
        
        // Generate/update changelog
        let generator = AIChangeLogGenerator(shell: shell)
        try generator.generateChangeLog(
            projectPath: projectFolder.path,
            version: versionString,
            dryRun: false
        )
        
        print("✅ CHANGELOG.md \(changelogExists ? "updated" : "created") for version \(versionString.green)")
        
        // Commit the changelog
        if picker.getPermission(prompt: "Commit the CHANGELOG update?") {
            let commitMessage = changelogExists
                ? "Update CHANGELOG.md for version \(versionString)"
                : "Add CHANGELOG.md for version \(versionString)"
            try gitHandler.commitAndPush(message: commitMessage, path: projectFolder.path)
            print("✅ CHANGELOG.md changes committed and pushed")
        }
    }
    
    /// Gets the actual version string from ReleaseVersionInfo.
    /// - Parameters:
    ///   - versionInfo: The release version information.
    ///   - previousVersion: The previous version string, if any.
    ///   - projectPath: The path to the project.
    /// - Returns: The resolved version string.
    /// - Throws: An error if the version cannot be determined.
    func getVersionString(versionInfo: ReleaseVersionInfo, previousVersion: String?, projectPath: String) throws -> String {
        switch versionInfo {
        case .version(let versionString):
            return versionString.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        case .increment(let versionPart):
            guard let previousVersion else {
                throw PublishExecutionError.noPreviousVersionToIncrement
            }
            return try VersionHandler.incrementVersion(for: versionPart, path: projectPath, previousVersion: previousVersion)
        }
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

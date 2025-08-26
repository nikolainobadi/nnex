//
//  Publish.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import NnexKit
import NnShellKit
import Foundation
import ArgumentParser

extension Nnex.Brew {
    struct Publish: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Publish an executable to GitHub and Homebrew for distribution.")
        
        @Option(name: .shortAndLong, help: "Path to the project directory where the release will be built. Defaults to the current directory.")
        var path: String?
        
        @Option(name: .shortAndLong, help: "The version number to publish or version part to increment: major, minor, patch.")
        var version: ReleaseVersionInfo?
        
        @Option(name: .shortAndLong, help: "The build type to set. Options: \(BuildType.allCases.map(\.rawValue).joined(separator: ", "))")
        var buildType: BuildType?
        
        @Option(name: .shortAndLong, help: "Release notes content provided directly.")
        var notes: String?

        @Option(name: [.customShort("F"), .customLong("notes-file")], help: "Path to a file containing release notes.")
        var notesFile: String?
        
        @Option(name: [.customShort("m"), .customLong("commit-message")], help: "The commit message when committing and pushing the tap to GitHub")
        var message: String?
        
        @Flag(name: .customLong("skip-tests"), help: "Skips running tests before publishing.")
        var skipTests = false

        func run() throws {
            let gitHandler = Nnex.makeGitHandler()
            try gitHandler.checkForGitHubCLI()
            
            let projectFolder = try Nnex.Brew.getProjectFolder(at: path)
            
            try ensureNoUncommittedChanges(at: projectFolder.path)
            
            let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler, shell: shell)
            let (resolvedVersionInfo, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: version, projectPath: projectFolder.path)
            
            let (tap, formula, buildType) = try getTapAndFormula(projectFolder: projectFolder, buildType: buildType)
            let binaryOutput = try buildBinary(formula: formula, buildType: buildType, skipTesting: skipTests)
            let archivedBinaries = try createArchives(from: binaryOutput)
            let assetURLs = try uploadRelease(folder: projectFolder, archivedBinaries: archivedBinaries, versionInfo: resolvedVersionInfo, previousVersion: previousVersion, releaseNotesSource: .init(notes: notes, notesFile: notesFile))
            
            let formulaContent = try makeFormulaContent(formula: formula, archivedBinaries: archivedBinaries, assetURLs: assetURLs)
            
            try publishFormula(formulaContent, formulaName: formula.name, message: message, tap: tap)
        }
    }
}


// MARK: - Private Helpers
private extension Nnex.Brew.Publish {
    /// Creates a shell instance for running commands.
    var shell: any Shell {
        return Nnex.makeShell()
    }
    
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
            throw PublishError.uncommittedChanges
        }
    }

    /// Creates a picker instance for user interactions.
    var picker: NnexPicker {
        return Nnex.makePicker()
    }

    /// Creates a Git handler instance for Git operations.
    var gitHandler: GitHandler {
        return Nnex.makeGitHandler()
    }

    /// Retrieves the Homebrew tap and formula associated with the project folder.
    /// - Parameters:
    ///   - projectFolder: The project folder.
    ///   - buildType: An optional build type to override the default.
    /// - Returns: A tuple containing the tap, formula, and build type.
    /// - Throws: An error if the tap or formula cannot be found.
    func getTapAndFormula(projectFolder: Folder, buildType: BuildType?) throws -> (SwiftDataTap, SwiftDataFormula, BuildType) {
        let context = try Nnex.makeContext()
        let buildType = buildType ?? context.loadDefaultBuildType()
        let loader = PublishInfoLoader(shell: shell, picker: picker, projectFolder: projectFolder, context: context, gitHandler: gitHandler, skipTests: skipTests)

        let (tap, formula) = try loader.loadPublishInfo()
        
        if formula.localProjectPath.isEmpty || formula.localProjectPath != projectFolder.path {
            formula.localProjectPath = projectFolder.path
            try context.saveChanges()
        }

        return (tap, formula, buildType)
    }

    /// Builds the binary for the given project and formula.
    /// - Parameters:
    ///   - formula: The Homebrew formula associated with the project.
    ///   - buildType: The type of build to perform.
    ///   - skipTesting: Whether or not to skip tests, if the formula contains a `TestCommand`
    /// - Returns: The binary output including path(s) and hash(es).
    /// - Throws: An error if the build process fails.
    func buildBinary(formula: SwiftDataFormula, buildType: BuildType, skipTesting: Bool) throws -> BinaryOutput {
        let testCommand = skipTesting ? nil : formula.testCommand
        let config = BuildConfig(projectName: formula.name, projectPath: formula.localProjectPath, buildType: buildType, extraBuildArgs: formula.extraBuildArgs, skipClean: false, testCommand: testCommand)
        let builder = ProjectBuilder(shell: shell, config: config)
        
        return try builder.build()
    }

    /// Creates tar.gz archives from binary output.
    /// - Parameter binaryOutput: The binary output from the build.
    /// - Returns: An array of archived binaries.
    /// - Throws: An error if archive creation fails.
    func createArchives(from binaryOutput: BinaryOutput) throws -> [ArchivedBinary] {
        let archiver = BinaryArchiver(shell: shell)
        
        switch binaryOutput {
        case .single(let info):
            return try archiver.createArchives(from: [info.path])
        case .multiple(let map):
            let binaryPaths = [ReleaseArchitecture.arm, ReleaseArchitecture.intel]
                .compactMap { map[$0]?.path }
            return try archiver.createArchives(from: binaryPaths)
        }
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
        let handler = ReleaseHandler(picker: picker, gitHandler: gitHandler, trashHandler: Nnex.makeTrashHandler())
        return try handler.uploadRelease(folder: folder, archivedBinaries: archivedBinaries, versionInfo: versionInfo, previousVersion: previousVersion, releaseNotesSource: releaseNotesSource)
    }

    /// Creates formula content based on the archived binaries and asset URLs.
    /// - Parameters:
    ///   - formula: The Homebrew formula.
    ///   - archivedBinaries: The archived binaries with their SHA256 values.
    ///   - assetURLs: The asset URLs from the GitHub release.
    /// - Returns: The formula content as a string.
    /// - Throws: An error if formula generation fails.
    func makeFormulaContent(formula: SwiftDataFormula, archivedBinaries: [ArchivedBinary], assetURLs: [String]) throws -> String {
        let formulaName = formula.name
        
        if archivedBinaries.count == 1 {
            // Single binary case
            guard let assetURL = assetURLs.first else {
                throw NnexError.missingSha256 // Should create a better error for missing URL
            }
            return FormulaContentGenerator.makeFormulaFileContent(
                name: formulaName,
                details: formula.details,
                homepage: formula.homepage,
                license: formula.license,
                assetURL: assetURL,
                sha256: archivedBinaries[0].sha256
            )
        } else {
            // Multiple binaries case - match archive paths to determine architecture
            var armArchive: ArchivedBinary?
            var intelArchive: ArchivedBinary?
            
            for archive in archivedBinaries {
                if archive.originalPath.contains("arm64-apple-macosx") {
                    armArchive = archive
                } else if archive.originalPath.contains("x86_64-apple-macosx") {
                    intelArchive = archive
                }
            }
            
            // Extract URLs - assuming first is ARM, second is Intel when both present
            var armURL: String?
            var intelURL: String?
            
            if armArchive != nil && intelArchive != nil {
                armURL = assetURLs.count > 0 ? assetURLs[0] : nil
                intelURL = assetURLs.count > 1 ? assetURLs[1] : nil
            } else if armArchive != nil {
                armURL = assetURLs.first
            } else if intelArchive != nil {
                intelURL = assetURLs.first
            }
            
            return FormulaContentGenerator.makeFormulaFileContent(
                name: formulaName,
                details: formula.details,
                homepage: formula.homepage,
                license: formula.license,
                armURL: armURL,
                armSHA256: armArchive?.sha256,
                intelURL: intelURL,
                intelSHA256: intelArchive?.sha256
            )
        }
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
}


// MARK: - Dependencies
struct ReleaseNotesSource {
    let notes: String?
    let notesFile: String?
}


// MARK: - Error Types
enum PublishError: Error, LocalizedError {
    case uncommittedChanges
    
    var errorDescription: String? {
        switch self {
        case .uncommittedChanges:
            return "Repository has uncommitted changes"
        }
    }
}


// MARK: - Extension Dependencies
extension ReleaseVersionInfo: ExpressibleByArgument { }
extension ReleaseVersionInfo.VersionPart: ExpressibleByArgument { }

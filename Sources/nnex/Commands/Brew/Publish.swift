//
//  Publish.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import NnexKit
import ArgumentParser

extension Nnex.Brew {
    struct Publish: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Publish an executable to GitHub and Homebrew for distribution.")
        
        @Option(name: .shortAndLong, help: "Path to the project directory where the release will be built. Defaults to the current directory.")
        var path: String?
        
        @Option(name: .shortAndLong, help: "The version number to publish or version part to increment: major, minor, patch.")
        var version: ReleaseVersionInfo?
        
        @Option(name: .shortAndLong, help: "The commit message when committing and pushing the tap to GitHub")
        var message: String?
        
        @Option(name: .shortAndLong, help: "The build type to set. Options: \(BuildType.allCases.map(\.rawValue).joined(separator: ", "))")
        var buildType: BuildType?
        
        func run() throws {
            try Nnex.makeGitHandler().ghVerification()
            
            let projectFolder = try getProjectFolder(at: path)
            let (tap, formula, buildType) = try getTapAndFormula(projectFolder: projectFolder, buildType: buildType)
            let binaryInfo = try buildBinary(for: projectFolder, formula: formula, buildType: buildType)
            let assetURL = try uploadRelease(folder: projectFolder, binaryInfo: binaryInfo, versionInfo: version)
            let formulaContent = FormulaContentGenerator.makeFormulaFileContent(formula: formula, assetURL: assetURL, sha256: binaryInfo.sha256)
            
            try publishFormula(formulaContent, formulaName: formula.name, message: message, tap: tap)
        }
    }
}


// MARK: - Private Helpers
private extension Nnex.Brew.Publish {
    /// Creates a shell instance for running commands.
    var shell: Shell {
        return Nnex.makeShell()
    }

    /// Creates a picker instance for user interactions.
    var picker: Picker {
        return Nnex.makePicker()
    }

    /// Creates a Git handler instance for Git operations.
    var gitHandler: GitHandler {
        return Nnex.makeGitHandler()
    }

    /// Retrieves the project folder from the specified path.
    /// - Parameter path: The file path to the project folder.
    /// - Returns: The folder at the specified path, or the current folder if no path is provided.
    /// - Throws: An error if the folder cannot be found or accessed.
    func getProjectFolder(at path: String?) throws -> Folder {
        if let path {
            return try Folder(path: path)
        }

        return Folder.current
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
        let loader = PublishInfoLoader(shell: shell, picker: picker, projectFolder: projectFolder, context: context, gitHandler: gitHandler)

        let (tap, formula) = try loader.loadPublishInfo()

        return (tap, formula, buildType)
    }

    /// Builds the binary for the given project and formula.
    /// - Parameters:
    ///   - folder: The project folder.
    ///   - formula: The Homebrew formula associated with the project.
    ///   - buildType: The type of build to perform.
    /// - Returns: The binary information including path and hash.
    /// - Throws: An error if the build process fails.
    func buildBinary(for folder: Folder, formula: SwiftDataFormula, buildType: BuildType) throws -> BinaryInfo {
        let builder = ProjectBuilder(shell: shell)

        return try builder.buildProject(name: folder.name, path: folder.path, buildType: buildType, extraBuildArgs: formula.extraBuildArgs)
    }

    /// Uploads a release to GitHub and returns the asset URL.
    /// - Parameters:
    ///   - folder: The project folder.
    ///   - binaryInfo: The binary information including path and hash.
    ///   - versionInfo: The version information for the release.
    /// - Returns: The URL of the uploaded asset.
    /// - Throws: An error if the upload process fails.
    func uploadRelease(folder: Folder, binaryInfo: BinaryInfo, versionInfo: ReleaseVersionInfo?) throws -> String {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: folder.path)
        let versionInfo = try versionInfo ?? getVersionInput(previousVersion: previousVersion)
        let releaseNotes = try picker.getRequiredInput(prompt: "Enter notes for this new release.")
        let releaseInfo = ReleaseInfo(binaryPath: binaryInfo.path, projectPath: folder.path, releaseNotes: releaseNotes, previousVersion: previousVersion, versionInfo: versionInfo)
        let store = ReleaseStore(gitHandler: gitHandler)
        let (assetURL, versionNumber) = try store.uploadRelease(info: releaseInfo)
        
        print("GitHub release \(versionNumber) created and binary uploaded to \(assetURL)")
        return assetURL
    }

    /// Gets version input from the user or calculates it based on the previous version.
    /// - Parameter previousVersion: The previous version string, if available.
    /// - Returns: A `ReleaseVersionInfo` object representing the new version.
    /// - Throws: An error if the version input is invalid.
    func getVersionInput(previousVersion: String?) throws -> ReleaseVersionInfo {
        var prompt = "\nEnter the version number for this release."

        if let previousVersion {
        prompt.append("\nPrevious release: \(previousVersion.yellow) (To increment, type either \("major".bold), \("minor".bold), or \("patch".bold))")
        } else {
            prompt.append(" (v1.1.0 or 1.1.0)")
        }

        let input = try picker.getRequiredInput(prompt: prompt)

        if let versionPart = ReleaseVersionInfo.VersionPart(string: input) {
            return .increment(versionPart)
        }

        return .version(input)
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


// MARK: - Extension Dependencies
extension ReleaseVersionInfo: @retroactive ExpressibleByArgument { }
extension ReleaseVersionInfo.VersionPart: @retroactive ExpressibleByArgument { }

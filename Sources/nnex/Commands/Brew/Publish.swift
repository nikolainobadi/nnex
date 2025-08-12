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
            try Nnex.makeGitHandler().checkForGitHubCLI()
            
            let projectFolder = try Nnex.Brew.getProjectFolder(at: path)
            let (tap, formula, buildType) = try getTapAndFormula(projectFolder: projectFolder, buildType: buildType)
            let binaryInfo = try buildBinary(formula: formula, buildType: buildType, skipTesting: skipTests)
            let assetURL = try uploadRelease(folder: projectFolder, binaryInfo: binaryInfo, versionInfo: version, releaseNotesSource: .init(notes: notes, notesFile: notesFile))
            let formulaContent = makeFormulaContent(formula: formula, assetURL: assetURL, sha256: binaryInfo.sha256)
            
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
    /// - Returns: The binary information including path and hash.
    /// - Throws: An error if the build process fails.
    func buildBinary(formula: SwiftDataFormula, buildType: BuildType, skipTesting: Bool) throws -> BinaryInfo {
        let testCommand = skipTesting ? nil : formula.testCommand
        let config = BuildConfig(projectName: formula.name, projectPath: formula.localProjectPath, buildType: buildType, extraBuildArgs: formula.extraBuildArgs, skipClean: false, testCommand: testCommand)
        let builder = ProjectBuilder(shell: shell, config: config)
        
        return try builder.build()
    }

    func uploadRelease(folder: Folder, binaryInfo: BinaryInfo, versionInfo: ReleaseVersionInfo?, releaseNotesSource: ReleaseNotesSource) throws -> String {
        let handler = ReleaseHandler(picker: picker, gitHandler: gitHandler)
            
        return try handler.uploadRelease(folder: folder, binaryInfo: binaryInfo, versionInfo: versionInfo, releaseNotesSource: releaseNotesSource)
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
    
    /// Creates formula content with sanitized name for valid Ruby class naming.
    /// - Parameters:
    ///   - formula: The formula containing the metadata.
    ///   - assetURL: The URL of the binary or tarball asset.
    ///   - sha256: The SHA256 hash of the asset.
    /// - Returns: The generated formula file content with a sanitized class name.
    func makeFormulaContent(formula: SwiftDataFormula, assetURL: String, sha256: String) -> String {
        let sanitizedClassName = FormulaNameSanitizer.sanitizeFormulaName(formula.name)
        let originalName = formula.name
        
        // We need to generate the formula content manually to use different names
        // for the class (sanitized) and the binary (original)
        return """
        class \(sanitizedClassName) < Formula
            desc "\(formula.details)"
            homepage "\(formula.homepage)"
            url "\(assetURL)"
            sha256 "\(sha256)"
            license "\(formula.license)"

            def install
                bin.install "\(originalName)"
            end

            test do
                system "#{bin}/\(originalName)", "--help"
            end
        end
        """
    }
}


// MARK: - Dependencies
struct ReleaseNotesSource {
    let notes: String?
    let notesFile: String?
}


// MARK: - Extension Dependencies
extension ReleaseVersionInfo: @retroactive ExpressibleByArgument { }
extension ReleaseVersionInfo.VersionPart: @retroactive ExpressibleByArgument { }

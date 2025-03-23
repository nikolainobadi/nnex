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
        static let configuration = CommandConfiguration(
            abstract: "Publish an executable to GitHub and Homebrew for distribution."
        )
        
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
            let binaryInfo = try buildBinary(for: projectFolder, buildType: buildType)
            let assetURL = try uploadRelease(folder: projectFolder, binaryInfo: binaryInfo, versionInfo: version)
            let formulaContent = FormulaContentGenerator.makeFormulaFileContent(formula: formula, assetURL: assetURL, sha256: binaryInfo.sha256)
            
            try publishFormula(formulaContent, formulaName: formula.name, message: message, tap: tap)
        }
    }
}


// MARK: - Private Helpers
private extension Nnex.Brew.Publish {
    var shell: Shell {
        return Nnex.makeShell()
    }
    
    var picker: Picker {
        return Nnex.makePicker()
    }
    
    var gitHandler: GitHandler {
        return Nnex.makeGitHandler()
    }
    
    func getProjectFolder(at path: String?) throws -> Folder {
        if let path {
            return try Folder(path: path)
        }
        
        return Folder.current
    }
    
    func getTapAndFormula(projectFolder: Folder, buildType: BuildType?) throws -> (SwiftDataTap, SwiftDataFormula, BuildType) {
        let context = try Nnex.makeContext()
        let buildType = buildType ?? context.loadDefaultBuildType()
        let loader = PublishInfoLoader(shell: shell, picker: picker, projectFolder: projectFolder, context: context, gitHandler: gitHandler)
        
        let (tap, formula) = try loader.loadPublishInfo()
        
        return (tap, formula, buildType)
    }
    
    func buildBinary(for folder: Folder, buildType: BuildType) throws -> BinaryInfo {
        let builder = ProjectBuilder(shell: shell)
        
        return try builder.buildProject(name: folder.name, path: folder.path, buildType: buildType)
    }
    
    func uploadRelease(folder: Folder, binaryInfo: BinaryInfo, versionInfo: ReleaseVersionInfo?) throws -> String {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: folder.path)
        let versionInfo = try getVersionInput(previousVersion: previousVersion)
        let releaseNotes = try picker.getRequiredInput(prompt: "Enter notes for this new release.")
        let releaseInfo = ReleaseInfo(binaryPath: binaryInfo.path, projectPath: folder.path, releaseNotes: releaseNotes, previousVersion: previousVersion, versionInfo: versionInfo)
        let store = ReleaseStore(gitHandler: gitHandler)
        
        let (assetURL, versionNumber) = try store.uploadRelease(info: releaseInfo)
        print("GitHub release \(versionNumber) created and binary uploaded to \(assetURL)")
        return assetURL
    }
    
    func getVersionInput(previousVersion: String?) throws -> ReleaseVersionInfo {
        var prompt = "Enter the version number for this release. (v1.1.0 or 1.1.0)"
        
        if let previousVersion {
            prompt.append(" Previous release: \(previousVersion) (To increment, simply type major, minor, or patch)")
        }
        
        let input = try picker.getRequiredInput(prompt: prompt)
        
        if let versionPart = ReleaseVersionInfo.VersionPart(string: input) {
            return .increment(versionPart)
        }
        
        return .version(input)
    }

    func publishFormula(_ content: String, formulaName: String, message: String?, tap: SwiftDataTap) throws {
        let publisher = FormulaPublisher(gitHandler: gitHandler)
        let commitMessage = try getMessage(message: message)
        
        let formulaPath = try publisher.publishFormula(content, formulaName: formulaName, commitMessage: commitMessage, tapFolderPath: tap.localPath)
        
        print("\nSuccessfully created formula at \(formulaPath)")
        if commitMessage != nil {
            print("pushed \(tap.name) to github.")
        }
    }
    
    func getMessage(message: String?) throws -> String? {
        if let message {
            return message
        }
        
        guard picker.getPermission(prompt: "Would you like to commit and push the tap to GitHub?") else {
            return nil
        }
        
        return try picker.getRequiredInput(prompt: "Enter your commit message.")
    }
}


// MARK: - Extension Dependencies
extension ReleaseVersionInfo: @retroactive ExpressibleByArgument { }
extension ReleaseVersionInfo.VersionPart: @retroactive ExpressibleByArgument { }

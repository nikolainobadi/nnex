//
//  Publish.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
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
            let shell = Nnex.makeShell()
            let context = try Nnex.makeContext()
            let gitHandler = Nnex.makeGitHandler()
            let fileSystem = Nnex.makeFileSystem()
            let resolvedBuildType = buildType ?? context.loadDefaultBuildType()
            let delegate = makePublishDelegate(shell: shell, gitHandler: gitHandler, fileSystem: fileSystem, context: context)
            let coordinator = PublishCoordinator(shell: shell, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
            
            try coordinator.publish(projectPath: path, buildType: resolvedBuildType, notes: notes, notesFilePath: notesFile, commitMessage: message, skipTests: skipTests, versionInfo: version)
        }
    }
}


// MARK: - Private Methods
private extension Nnex.Brew.Publish {
    func makeBuildController(shell: any NnexShell, picker: any NnexPicker, fileSystem: any FileSystem, folderBrowser: any DirectoryBrowser) -> BuildController {
        let buildService = BuildManager(shell: shell, fileSystem: fileSystem)
        
        return .init(shell: shell, picker: picker, fileSystem: fileSystem, buildService: buildService, folderBrowser: folderBrowser)
    }
    
    func makeArtifactController(shell: any NnexShell, picker: any NnexPicker, fileSystem: any FileSystem, loader: PublishInfoStoreAdapter, buildController: BuildController) -> ArtifactController {
        let artifactDelegate = ArtifactDelegateAdapter(loader: loader, buildController: buildController)
        
        return .init(shell: shell, picker: picker, fileSystem: fileSystem, delegate: artifactDelegate)
    }
    
    func makePublishDelegate(shell: any NnexShell, gitHandler: any GitHandler, fileSystem: any FileSystem, context: NnexContext) -> any PublishDelegate {
        let picker = Nnex.makePicker()
        let folderBrowser = Nnex.makeFolderBrowser(picker: picker, fileSystem: fileSystem)
        let dateProvider = DefaultDateProvider()
        let loader = PublishInfoStoreAdapter(context: context)

        let versionService = AutoVersionHandler(shell: shell, fileSystem: fileSystem)
        let versionController = VersionNumberController(shell: shell, picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, versionService: versionService)
        let buildController = makeBuildController(shell: shell, picker: picker, fileSystem: fileSystem, folderBrowser: folderBrowser)
        let artifactController = makeArtifactController(shell: shell, picker: picker, fileSystem: fileSystem, loader: loader, buildController: buildController)
        let releaseController = GithubReleaseController(picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, dateProvider: dateProvider, folderBrowser: folderBrowser)
        let publishController = FormulaPublishController(picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, store: loader)
        
        return PublishDelegateAdapter(versionController: versionController, artifactController: artifactController, releaseController: releaseController, publishController: publishController)
    }
}


// MARK: - Extension Dependencies
extension AutoVersionHandler: VersionNumberService { }
extension ReleaseVersionInfo: ExpressibleByArgument { }
extension ReleaseVersionInfo.VersionPart: ExpressibleByArgument { }

private extension FileSystem {
    func getProjectFolder(at path: String?) throws -> any Directory {
        if let path {
            return try directory(at: path)
        }
        
        return currentDirectory
    }
}

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
            let picker = Nnex.makePicker()
            let gitHandler = Nnex.makeGitHandler()
            let context = try Nnex.makeContext()
            let fileSystem = Nnex.makeFileSystem()
            let folderBrowser = Nnex.makeFolderBrowser(picker: picker, fileSystem: fileSystem)
            let resolvedBuildType = buildType ?? context.loadDefaultBuildType()
            let dateProvider = DefaultDateProvider()
            
            let buildService = BuildManager(shell: shell, fileSystem: fileSystem)
            let buildController = BuildController(shell: shell, picker: picker, fileSystem: fileSystem, buildService: buildService, folderBrowser: folderBrowser)
            let loader = PublishInfoStoreAdapter(context: context)
            let artifactDelegate = ArtifactDelegateAdapter(loader: loader, buildController: buildController)
            let artifactController = ArtifactController(shell: shell, picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, delegate: artifactDelegate)
            let releaseController = GithubReleaseController(picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, dateProvider: dateProvider, folderBrowser: folderBrowser)
            let publishController = FormulaPublishController(picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, store: loader)
            let delegate = PublishDelegateAdapter(artifactController: artifactController, releaseController: releaseController, publishController: publishController)
            let coordinator = PublishCoordinator(shell: shell, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
            
            try coordinator.publish(projectPath: path, buildType: resolvedBuildType, notes: notes, notesFilePath: notesFile, commitMessage: message, skipTests: skipTests, versionInfo: version)
            
//            let manager = BuildManager(shell: shell, fileSystem: fileSystem)
//            let buildController = BuildController(shell: shell, picker: picker, fileSystem: fileSystem, buildService: manager, folderBrowser: folderBrowser)
//            let publishAdapter = PublishInfoStoreAdapter(context: context)
//            let temp = TemporaryPublishAdapter(context: context, buildController: buildController, publishInfoStoreAdatper: publishAdapter)
//            let coordinator = OldPublishCoordinator(shell: shell, picker: picker, fileSystem: fileSystem, gitHandler: gitHandler, dateProvider: dateProvider, folderBrowser: folderBrowser, temporaryProtocol: temp)
//            
//            try coordinator.publish(projectPath: path, buildType: resolvedBuildType, notes: notes, notesFilePath: notesFile, commitMessage: message, skipTests: skipTests, version: version)
            
//            let projectFolder = try fileSystem.getProjectFolder(at: path)
//            let store = PublishInfoStoreAdapter(context: context)
//            let publishInfoLoader = PublishInfoLoader(shell: shell, picker: picker, gitHandler: gitHandler, store: store, projectFolder: projectFolder, skipTests: skipTests)
//            let manager = PublishExecutionManager(shell: shell, picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, folderBrowser: folderBrowser, publishInfoLoader: publishInfoLoader)
            
//            try manager.executePublish(projectFolder: projectFolder, version: version, buildType: resolvedBuildType, notes: notes, notesFile: notesFile, message: message, skipTests: skipTests)
        }
    }
}


// MARK: - Private Methods
private extension FileSystem {
    func getProjectFolder(at path: String?) throws -> any Directory {
        if let path {
            return try directory(at: path)
        }
        
        return currentDirectory
    }
}


// MARK: - Extension Dependencies
extension ReleaseVersionInfo: ExpressibleByArgument { }
extension ReleaseVersionInfo.VersionPart: ExpressibleByArgument { }

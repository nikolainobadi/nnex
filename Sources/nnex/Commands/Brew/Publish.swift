//
//  Publish.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
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
            fatalError() // TODO: - 
//            let shell = Nnex.makeShell()
//            let picker = Nnex.makePicker()
//            let gitHandler = Nnex.makeGitHandler()
//            let context = try Nnex.makeContext()
//            let buildType = buildType ?? context.loadDefaultBuildType()
//            let projectFolder = try Nnex.Brew.getProjectFolder(at: path)
//            let trashHandler = Nnex.makeTrashHandler()
//            let publishInfoLoader = PublishInfoLoader(shell: shell, picker: picker, projectFolder: projectFolder, context: context, gitHandler: gitHandler, skipTests: skipTests)
//            let manager = PublishExecutionManager(shell: shell, picker: picker, gitHandler: gitHandler, publishInfoLoader: publishInfoLoader, trashHandler: trashHandler)
//            
//            try manager.executePublish(
//                projectFolder: projectFolder,
//                version: version,
//                buildType: buildType,
//                notes: notes,
//                notesFile: notesFile,
//                message: message,
//                skipTests: skipTests
//            )
        }
    }
}



// MARK: - Extension Dependencies
extension ReleaseVersionInfo: ExpressibleByArgument { }
extension ReleaseVersionInfo.VersionPart: ExpressibleByArgument { }

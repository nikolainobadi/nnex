//
//  PublishCoordinator.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit

struct PublishCoordinator {
    private let shell: any NnexShell
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let delegate: any PublishDelegate
    
    init(shell: any NnexShell, gitHandler: any GitHandler, fileSystem: any FileSystem, delegate: any PublishDelegate) {
        self.shell = shell
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
        self.delegate = delegate
    }
}


// MARK: - Publish
extension PublishCoordinator {
    func publish(projectPath: String?, buildType: BuildType, notes: String?, notesFilePath: String?, commitMessage: String?, skipTests: Bool, versionInfo: ReleaseVersionInfo?) throws {
        let projectFolder = try fileSystem.getDirectoryAtPathOrCurrent(path: projectPath)
        
        try verifyPublishRequirements(at: projectFolder.path)
        
        let nextVersionNumber = try delegate.resolveNextVersionNumber(projectPath: projectFolder.path, versionInfo: versionInfo)
        let artifact = try delegate.buildArtifacts(projectFolder: projectFolder, buildType: buildType, versionNumber: nextVersionNumber)
        let assetURLs = try delegate.uploadRelease(version: artifact.version, assets: artifact.archives, notes: notes, notesFilePath: notesFilePath, projectFolder: projectFolder)
        let publishInfo = makePublishInfo(artifact: artifact, assetURLs: assetURLs)
        
        try delegate.publishFormula(projectFolder: projectFolder, info: publishInfo, commitMessage: commitMessage)
    }
}


// MARK: - Private Methods
private extension PublishCoordinator {
    func makePublishInfo(artifact: ReleaseArtifact, assetURLs: [String]) -> FormulaPublishInfo {
        return .init(version: artifact.version, installName: artifact.executableName, assetURLs: assetURLs, archives: artifact.archives)
    }
    
    func verifyPublishRequirements(at path: String) throws {
        try gitHandler.checkForGitHubCLI()
        try ensureNoUncommittedChanges(at: path)
        // TODO: - check for main branch?
    }
    
    func ensureNoUncommittedChanges(at path: String) throws {
        let result = try shell.bash("cd \"\(path)\" && git status --porcelain")
        
        if !result.isEmpty {
            print("""
            There are uncommitted changes in the repository at \(path.yellow):
            
            \(result)
            
            Please commit or stash your changes before publishing.
            """)
            throw NnexError.uncommittedChanges 
        }
    }
}


// MARK: - Dependencies
protocol PublishDelegate {
    func resolveNextVersionNumber(projectPath: String, versionInfo: ReleaseVersionInfo?) throws -> String
    func buildArtifacts(projectFolder folder: any Directory, buildType: BuildType, versionNumber: String) throws -> ReleaseArtifact
    func uploadRelease(version: String, assets: [ArchivedBinary], notes: String?, notesFilePath: String?, projectFolder: any Directory) throws -> [String]
    func publishFormula(projectFolder: any Directory, info: FormulaPublishInfo, commitMessage: String?) throws
}

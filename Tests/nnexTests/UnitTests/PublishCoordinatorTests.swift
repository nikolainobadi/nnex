//
//  PublishCoordinatorTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit
import Testing
import Foundation
import GitShellKit
import NnShellTesting
import NnexSharedTestHelpers
@testable import nnex

final class PublishCoordinatorTests {
    @Test("Publishes using provided path and delegates artifact, release, and formula steps")
    func publishOrchestratesHappyPath() throws {
        let projectPath = "/projects/app"
        let project = MockDirectory(path: projectPath)
        let fileSystem = MockFileSystem(directoryMap: [projectPath: project])
        let shell = makeShell(statusOutput: "")
        let gitHandler = MockPublishGitHandler()
        let artifact = ReleaseArtifact(
            version: "1.0.0",
            executableName: "App",
            archives: [ArchivedBinary(originalPath: "/tmp/app", archivePath: "/tmp/app.tar.gz", sha256: "abc123")]
        )
        let delegate = MockPublishDelegate(artifactToReturn: artifact, assetURLsToReturn: ["primary"])
        let sut = PublishCoordinator(shell: shell, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
        
        try sut.publish(projectPath: projectPath, buildType: .universal, notes: "notes", notesFilePath: nil, commitMessage: "commit", skipTests: true, versionInfo: .version("1.0.0"))
        
        #expect(gitHandler.ghChecked)
        #expect(delegate.capturedBuild?.folder.path == projectPath)
        #expect(delegate.capturedBuild?.buildType == .universal)
        #expect(delegate.capturedUpload?.version == artifact.version)
        #expect(delegate.capturedUpload?.assets.first?.archivePath == artifact.archives.first?.archivePath)
        #expect(delegate.capturedUpload?.notes == "notes")
        #expect(delegate.capturedPublishInfo?.version == artifact.version)
        #expect(delegate.capturedPublishInfo?.assetURLs == ["primary"])
        #expect(delegate.capturedCommitMessage == "commit")
        #expect(shell.executedCommand(containing: "git status --porcelain"))
    }
    
    @Test("Uses current directory when no path provided")
    func publishUsesCurrentDirectoryWhenPathNil() throws {
        let current = MockDirectory(path: "/current/dir")
        let fileSystem = MockFileSystem(currentDirectory: current, directoryMap: [current.path: current])
        let shell = makeShell(statusOutput: "", path: current.path)
        let gitHandler = MockPublishGitHandler()
        let delegate = MockPublishDelegate()
        let sut = PublishCoordinator(shell: shell, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
        
        try sut.publish(projectPath: nil, buildType: .arm64, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: false, versionInfo: nil)
        
        #expect(delegate.capturedBuild?.folder.path == current.path)
        #expect(delegate.capturedBuild?.buildType == .arm64)
        #expect(delegate.capturedUpload?.version == delegate.artifactToReturn.version)
    }
    
    @Test("Throws when uncommitted changes exist")
    func publishFailsOnUncommittedChanges() {
        let projectPath = "/projects/app"
        let project = MockDirectory(path: projectPath)
        let fileSystem = MockFileSystem(directoryMap: [projectPath: project])
        let shell = makeShell(statusOutput: " M file.swift", path: projectPath)
        let gitHandler = MockPublishGitHandler()
        let delegate = MockPublishDelegate()
        let sut = PublishCoordinator(shell: shell, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
        
        #expect(throws: NnexError.uncommittedChanges) {
            try sut.publish(projectPath: projectPath, buildType: .universal, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: true, versionInfo: nil)
        }
        
        #expect(delegate.capturedBuild == nil)
        #expect(delegate.capturedUpload == nil)
        #expect(delegate.capturedPublishInfo == nil)
    }
    
    @Test("Propagates GitHub CLI verification errors")
    func publishPropagatesGhCheckFailure() {
        let projectPath = "/projects/app"
        let project = MockDirectory(path: projectPath)
        let fileSystem = MockFileSystem(directoryMap: [projectPath: project])
        let shell = makeShell(statusOutput: "", path: projectPath)
        let gitHandler = MockPublishGitHandler(shouldThrow: true)
        let delegate = MockPublishDelegate()
        let sut = PublishCoordinator(shell: shell, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
        
        #expect(throws: (any Error).self) {
            try sut.publish(projectPath: projectPath, buildType: .arm64, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: true, versionInfo: nil)
        }
        
        #expect(delegate.capturedBuild == nil)
    }
}


// MARK: - Helpers
private extension PublishCoordinatorTests {
    func makeShell(statusOutput: String, path: String = "/projects/app") -> MockShell {
        let statusCommand = "cd \"\(path)\" && git status --porcelain"
        return MockShell(commands: [MockCommand(command: statusCommand, output: statusOutput)])
    }
}


// MARK: - Mocks
private extension PublishCoordinatorTests {
    final class MockPublishGitHandler: GitHandler {
        let shouldThrow: Bool
        private(set) var ghChecked = false
        
        init(shouldThrow: Bool = false) {
            self.shouldThrow = shouldThrow
        }
        
        func ghVerification() throws {
            ghChecked = true
            if shouldThrow { throw NnexError.missingGitHubCLI }
        }
        
        func gitInit(path: String) throws { }
        func getRemoteURL(path: String) throws -> String { "" }
        func commitAndPush(message: String, path: String) throws { }
        func getPreviousReleaseVersion(path: String) throws -> String { "" }
        func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String { "" }
        func createNewRelease(version: String, archivedBinaries: [ArchivedBinary], releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> [String] { [] }
    }
    
    final class MockPublishDelegate: PublishDelegate {
        let artifactToReturn: ReleaseArtifact
        let assetURLsToReturn: [String]
        
        private(set) var capturedBuild: (folder: any Directory, buildType: BuildType, versionInfo: ReleaseVersionInfo?)?
        private(set) var capturedUpload: (version: String, assets: [ArchivedBinary], notes: String?, notesFilePath: String?, projectFolder: any Directory)?
        private(set) var capturedPublishInfo: FormulaPublishInfo?
        private(set) var capturedCommitMessage: String?
        
        init(
            artifactToReturn: ReleaseArtifact = .init(version: "1.0.0", executableName: "App", archives: [ArchivedBinary(originalPath: "/tmp/app", archivePath: "/tmp/app.tar.gz", sha256: "abc123")]),
            assetURLsToReturn: [String] = ["asset"]
        ) {
            self.artifactToReturn = artifactToReturn
            self.assetURLsToReturn = assetURLsToReturn
        }
        
        func buildArtifacts(projectFolder folder: any Directory, buildType: BuildType, versionInfo: ReleaseVersionInfo?) throws -> ReleaseArtifact {
            capturedBuild = (folder, buildType, versionInfo)
            return artifactToReturn
        }
        
        func uploadRelease(version: String, assets: [ArchivedBinary], notes: String?, notesFilePath: String?, projectFolder: any Directory) throws -> [String] {
            capturedUpload = (version, assets, notes, notesFilePath, projectFolder)
            return assetURLsToReturn
        }
        
        func publishFormula(projectFolder: any Directory, info: FormulaPublishInfo, commitMessage: String?) throws {
            capturedPublishInfo = info
            capturedCommitMessage = commitMessage
        }
    }
}

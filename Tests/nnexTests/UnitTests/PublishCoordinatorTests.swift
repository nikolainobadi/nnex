//
//  PublishCoordinatorTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit
import Testing
import Foundation
import NnShellTesting
import NnexSharedTestHelpers
@testable import nnex

struct PublishCoordinatorTests {
    @Test("Starting values are empty")
    func startingValuesEmpty() {
        let (_, delegate) = makeSUT()

        #expect(delegate.publishResults == nil)
    }
}


// MARK: - Publish Flow
extension PublishCoordinatorTests {
    @Test("Publishes formula with correct info and commit message")
    func publishesFormulaWithCorrectInfoAndMessage() throws {
        let expectedVersion = "2.0.0"
        let expectedAssetURLs = ["https://example.com/asset1", "https://example.com/asset2"]
        let expectedCommitMessage = "Release v2.0.0"
        let (sut, delegate) = makeSUT(version: expectedVersion, assetURLsToReturn: expectedAssetURLs)

        try sut.publish(projectPath: nil, buildType: .universal, notes: nil, notesFilePath: nil, commitMessage: expectedCommitMessage, skipTests: true, versionInfo: nil)

        let results = try #require(delegate.publishResults)

        #expect(results.info.version == expectedVersion)
        #expect(results.info.installName == "App")
        #expect(results.info.assetURLs == expectedAssetURLs)
        #expect(results.info.archives.count == 1)
        #expect(results.message == expectedCommitMessage)
    }

    @Test("Publishes with nil commit message")
    func publishesWithNilCommitMessage() throws {
        let (sut, delegate) = makeSUT()

        try sut.publish(projectPath: nil, buildType: .universal, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: true, versionInfo: nil)

        let results = try #require(delegate.publishResults)

        #expect(results.message == nil)
    }

    @Test("Publishes with multiple archives")
    func publishesWithMultipleArchives() throws {
        let archives = [
            makeArchive(originalPath: "/tmp/app-arm64", archivePath: "/tmp/app-arm64.tar.gz", sha256: "abc123"),
            makeArchive(originalPath: "/tmp/app-x86", archivePath: "/tmp/app-x86.tar.gz", sha256: "def456")
        ]
        let artifact = makeReleaseArfifact(version: "1.5.0", archives: archives)
        let (sut, delegate) = makeSUT(artifactToReturn: artifact)

        try sut.publish(projectPath: nil, buildType: .universal, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: true, versionInfo: nil)

        let results = try #require(delegate.publishResults)

        #expect(results.info.archives.count == 2)
        #expect(results.info.archives[0].sha256 == "abc123")
        #expect(results.info.archives[1].sha256 == "def456")
    }

    @Test("Publishes with custom executable name")
    func publishesWithCustomExecutableName() throws {
        let customName = "MyCustomApp"
        let artifact = makeReleaseArfifact(version: "1.0.0", executableName: customName)
        let (sut, delegate) = makeSUT(artifactToReturn: artifact)

        try sut.publish(projectPath: nil, buildType: .universal, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: true, versionInfo: nil)

        let results = try #require(delegate.publishResults)

        #expect(results.info.installName == customName)
    }

    @Test("Publishes with arm64 build type")
    func publishesWithArm64BuildType() throws {
        let (sut, delegate) = makeSUT()

        try sut.publish(projectPath: nil, buildType: .arm64, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: true, versionInfo: nil)

        let results = try #require(delegate.publishResults)

        #expect(results.info.version == "2.0.0")
    }

    @Test("Publishes with x86_64 build type")
    func publishesWithX8664BuildType() throws {
        let (sut, delegate) = makeSUT()

        try sut.publish(projectPath: nil, buildType: .x86_64, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: true, versionInfo: nil)

        let results = try #require(delegate.publishResults)

        #expect(results.info.version == "2.0.0")
    }
}


// MARK: - Verification
extension PublishCoordinatorTests {
    @Test("Throws when GitHub CLI is not installed")
    func throwsWhenGitHubCLINotInstalled() throws {
        let (sut, _) = makeSUT(ghIsInstalled: false)

        #expect(throws: NnexError.missingGitHubCLI) {
            try sut.publish(projectPath: nil, buildType: .universal, notes: nil, notesFilePath: nil, commitMessage: nil, skipTests: true, versionInfo: nil)
        }
    }
}


// MARK: - SUT
private extension PublishCoordinatorTests {
    func makeSUT(version: String = "2.0.0", artifactToReturn: ReleaseArtifact? = nil, assetURLsToReturn: [String] = [], ghIsInstalled: Bool = true, throwError: Bool = false) -> (sut: PublishCoordinator, delegate: MockDelegate) {
        let shell = MockShell()
        let gitHandler = MockGitHandler(ghIsInstalled: ghIsInstalled)
        let fileSystem = MockFileSystem()
        let delegate = MockDelegate(
            versionNumber: version,
            artifactToReturn: artifactToReturn ?? makeReleaseArfifact(version: version),
            assetURLsToReturn: assetURLsToReturn,
            throwError: throwError
        )
        let sut = PublishCoordinator(shell: shell, gitHandler: gitHandler, fileSystem: fileSystem, delegate: delegate)
        
        return (sut, delegate)
    }
    
    func makeReleaseArfifact(version: String, executableName: String = "App", archives: [ArchivedBinary]? = nil) -> ReleaseArtifact {
        return .init(
            version: version,
            executableName: executableName,
            archives: archives ?? [makeArchive()]
        )
    }
    
    func makeArchive(originalPath: String = "/tmp/app", archivePath: String = "/tmp/app.tar.gz", sha256: String = "abc123") -> ArchivedBinary {
        return .init(originalPath: originalPath, archivePath: archivePath, sha256: sha256)
    }
}


// MARK: - Mocks
private extension PublishCoordinatorTests {
    final class MockDelegate: PublishDelegate {
        private let throwError: Bool
        private let versionNumber: String
        private let artifactToReturn: ReleaseArtifact
        private let assetURLsToReturn: [String]
        
        private(set) var publishResults: (folder: any Directory, info: FormulaPublishInfo, message: String?)?
        
        init(versionNumber: String, artifactToReturn: ReleaseArtifact, assetURLsToReturn: [String], throwError: Bool) {
            self.throwError = throwError
            self.versionNumber = versionNumber
            self.artifactToReturn = artifactToReturn
            self.assetURLsToReturn = assetURLsToReturn
        }
        
        func resolveNextVersionNumber(projectPath: String, versionInfo: ReleaseVersionInfo?) throws -> String {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            return versionNumber
        }
        
        func buildArtifacts(projectFolder folder: any Directory, buildType: BuildType, versionNumber: String) throws -> ReleaseArtifact {
            if throwError { throw NSError(domain: "Test", code: 0) }
            // TODO: -
            return artifactToReturn
        }
        
        func uploadRelease(version: String, assets: [ArchivedBinary], notes: String?, notesFilePath: String?, projectFolder: any Directory) throws -> [String] {
            if throwError { throw NSError(domain: "Test", code: 0) }
           // TODO: -
            
            return assetURLsToReturn
        }
        
        func publishFormula(projectFolder: any Directory, info: FormulaPublishInfo, commitMessage: String?) throws {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            publishResults = (projectFolder, info, commitMessage)
        }
    }
}

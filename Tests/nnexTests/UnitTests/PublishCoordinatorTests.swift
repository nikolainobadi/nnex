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
    
    func makeReleaseArfifact(version: String) -> ReleaseArtifact {
        return .init(
            version: version,
            executableName: "App",
            archives: [.init(originalPath: "/tmp/app", archivePath: "/tmp/app.tar.gz", sha256: "abc123")]
        )
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

//
//  ReleaseStoreTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Testing
import GitCommandGen
import NnexSharedTestHelpers
@testable import NnexKit

struct ReleaseStoreTests {
    private let version = "1.0.0"
    private let assetURL = "https://github.com/test/binary1"
}


// MARK: - Unit Tests
extension ReleaseStoreTests {
    @Test("Start values are empty")
    func emptyStartingValues() {
        let (_, gitHandler) = makeSUT()
        
        #expect(gitHandler.releaseVersion == nil)
    }
    
    @Test("Uploads a release and returns binary URL")
    func uploadRelease() throws {
        let info = makeReleaseInfo(versionInfo: .version(version))
        let (sut, gitHandler) = makeSUT()
        let result = try sut.uploadRelease(info: info)
        
        #expect(result.assertURL == assetURL)
        #expect(result.versionNumber == version)
        #expect(gitHandler.releaseVersion == version)
    }
    
    @Test("Throws error if shell command fails during release upload")
    func uploadReleaseShellError() throws {
        let info = makeReleaseInfo()
        let sut = makeSUT(throwError: true).sut

        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info)
        }
    }
    
    @Test("Uploads release with incremented version (major)")
    func uploadReleaseWithIncrementedVersion() throws {
        let previousRelease = "1.0.0"
        let expectedRelease = "2.0.0"
        let info = makeReleaseInfo(previousVersion: previousRelease, versionInfo: .increment(.major))
        let (sut, gitHandler) = makeSUT()
        let result = try sut.uploadRelease(info: info)
        
        #expect(result.assertURL == assetURL)
        #expect(result.versionNumber == expectedRelease)
        #expect(gitHandler.releaseVersion == expectedRelease)
    }
    
    @Test("Does not create release if version number is invalid")
    func invalidVersionNumberError() throws {
        let info = makeReleaseInfo(versionInfo: .version("123"))
        let (sut, gitHandler) = makeSUT()
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info)
        }
        
        #expect(gitHandler.releaseVersion == nil)
    }
    
    @Test("Throws error if previous version doesn't exist when trying to increment", arguments: ReleaseVersionInfo.VersionPart.allCases)
    func previousVersionError(versionPart: ReleaseVersionInfo.VersionPart) throws {
        let info = makeReleaseInfo(versionInfo: .increment(versionPart))
        let (sut, _) = makeSUT()
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info)
        }
    }
}

// MARK: - SUT
private extension ReleaseStoreTests {
    func makeSUT(assetURL: String? = nil, throwError: Bool = false) -> (sut: ReleaseStore, gitHandler: MockGitHandler) {
        let gitHandler = MockGitHandler(assetURL: assetURL ?? self.assetURL, throwError: throwError)
        let sut = ReleaseStore(gitHandler: gitHandler)
        
        return (sut, gitHandler)
    }
    
    func makeReleaseInfo(binaryPath: String = "path/to/binary", projectPath: String = "path/to/project", releaseNoteInfo: ReleaseNoteInfo = .init(content: "release notes", isFromFile: false) , previousVersion: String? = nil, versionInfo: ReleaseVersionInfo = .version("1.0.0")) -> ReleaseInfo {
        return .init(binaryPath: binaryPath, projectPath: projectPath, releaseNoteInfo: releaseNoteInfo, previousVersion: previousVersion, versionInfo: versionInfo)
    }
}

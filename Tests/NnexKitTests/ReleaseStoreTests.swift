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
    private let additionalAssetPath1 = "path/to/binary2"
    private let additionalAssetPath2 = "path/to/binary3"
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
        let mockArchived = ArchivedBinary(originalPath: "/test/path", archivePath: "/test/archive.tar.gz", sha256: "testhash")
        let result = try sut.uploadRelease(info: info, archivedBinaries: [mockArchived])
        
        #expect(result.assetURLs.count == 1)
        #expect(result.assetURLs.first == assetURL)
        #expect(result.versionNumber == version)
        #expect(gitHandler.releaseVersion == version)
    }
    
    @Test("Uploads a release with additional assets and returns all URLs")
    func uploadReleaseWithAdditionalAssets() throws {
        let info = makeReleaseInfo(versionInfo: .version(version))
        let (sut, gitHandler) = makeSUT()
        let mockArchived = ArchivedBinary(originalPath: "/test/path", archivePath: "/test/archive.tar.gz", sha256: "testhash")
        let mockArchived1 = ArchivedBinary(originalPath: additionalAssetPath1, archivePath: "/tmp/archive1.tar.gz", sha256: "hash1")
        let mockArchived2 = ArchivedBinary(originalPath: additionalAssetPath2, archivePath: "/tmp/archive2.tar.gz", sha256: "hash2")
        let result = try sut.uploadRelease(info: info, archivedBinaries: [mockArchived, mockArchived1, mockArchived2])
        
        #expect(result.assetURLs.count == 3) // Primary + 2 additional
        #expect(result.assetURLs.first == assetURL) // Primary asset URL
        #expect(result.assetURLs[1] == "\(assetURL)-additional-1") // First additional
        #expect(result.assetURLs[2] == "\(assetURL)-additional-2") // Second additional
        #expect(result.versionNumber == version)
        #expect(gitHandler.releaseVersion == version)
    }
    
    @Test("Uploads release with empty additional assets array")
    func uploadReleaseWithEmptyAdditionalAssets() throws {
        let info = makeReleaseInfo(versionInfo: .version(version))
        let (sut, gitHandler) = makeSUT()
        let mockArchived = ArchivedBinary(originalPath: "/test/path", archivePath: "/test/archive.tar.gz", sha256: "testhash")
        let result = try sut.uploadRelease(info: info, archivedBinaries: [mockArchived])
        
        #expect(result.assetURLs.count == 1) // Only primary
        #expect(result.assetURLs.first == assetURL)
        #expect(result.versionNumber == version)
        #expect(gitHandler.releaseVersion == version)
    }
    
    @Test("Throws error if shell command fails during release upload")
    func uploadReleaseShellError() throws {
        let info = makeReleaseInfo()
        let sut = makeSUT(throwError: true).sut

        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info, archivedBinaries: [])
        }
    }
    
    @Test("Uploads release with incremented version (major)")
    func uploadReleaseWithIncrementedVersion() throws {
        let previousRelease = "1.0.0"
        let expectedRelease = "2.0.0"
        let info = makeReleaseInfo(previousVersion: previousRelease, versionInfo: .increment(.major))
        let (sut, gitHandler) = makeSUT()
        let mockArchived = ArchivedBinary(originalPath: "/test/path", archivePath: "/test/archive.tar.gz", sha256: "testhash")
        let result = try sut.uploadRelease(info: info, archivedBinaries: [mockArchived])
        
        #expect(result.assetURLs.count == 1)
        #expect(result.assetURLs.first == assetURL)
        #expect(result.versionNumber == expectedRelease)
        #expect(gitHandler.releaseVersion == expectedRelease)
    }
    
    @Test("Does not create release if version number is invalid")
    func invalidVersionNumberError() throws {
        let info = makeReleaseInfo(versionInfo: .version("123"))
        let (sut, gitHandler) = makeSUT()
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info, archivedBinaries: [])
        }
        
        #expect(gitHandler.releaseVersion == nil)
    }
    
    @Test("Throws error if previous version doesn't exist when trying to increment", arguments: OldReleaseVersionInfo.VersionPart.allCases)
    func previousVersionError(versionPart: OldReleaseVersionInfo.VersionPart) throws {
        let info = makeReleaseInfo(versionInfo: .increment(versionPart))
        let (sut, _) = makeSUT()
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info, archivedBinaries: [])
        }
    }
}

// MARK: - SUT
private extension ReleaseStoreTests {
    func makeSUT(assetURL: String? = nil, throwError: Bool = false) -> (sut: OldReleaseStore, gitHandler: MockGitHandler) {
        let gitHandler = MockGitHandler(assetURL: assetURL ?? self.assetURL, throwError: throwError)
        let sut = OldReleaseStore(gitHandler: gitHandler)
        
        return (sut, gitHandler)
    }
    
    func makeReleaseInfo(projectPath: String = "path/to/project", releaseNoteInfo: ReleaseNoteInfo = .init(content: "release notes", isFromFile: false) , previousVersion: String? = nil, versionInfo: OldReleaseVersionInfo = .version("1.0.0")) -> OldReleaseInfo {
        return .init(projectPath: projectPath, releaseNoteInfo: releaseNoteInfo, previousVersion: previousVersion, versionInfo: versionInfo)
    }
}

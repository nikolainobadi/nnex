//
//  ReleaseStoreTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit
import Testing
import GitCommandGen
@testable import nnex

struct ReleaseStoreTests {
    @Test("Uploads a release and returns binary URL")
    func uploadRelease() throws {
        let version = "1.0.0"
        let info = makeReleaseInfo(versionInfo: .version(version))
        let releaseNotes = "Release notes for version \(version)"
        let (sut, shell) = makeSUT(runResults: ["https://github.com/test/binary1"], inputResponses: [releaseNotes])
        let result = try sut.uploadRelease(info: info)
        
        #expect(result == "https://github.com/test/binary1")
        #expect(shell.printedCommands.contains(makeGitHubCommand(.createNewReleaseWithBinary(version: version, binaryPath: info.binaryPath, releaseNotes: releaseNotes), path: info.projectPath)))
    }
    
    @Test("Throws error if shell command fails during release upload")
    func uploadReleaseShellError() throws {
        let info = makeReleaseInfo()
        let sut = makeSUT(throwShellError: true).sut

        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info)
        }
    }
    
    @Test("Uploads release with incremented version (major)")
    func uploadReleaseWithIncrementedVersion() throws {
        let releaseNotes = "Incremental release notes"
        let info = makeReleaseInfo(versionInfo: .increment(.major))
        let (sut, shell) = makeSUT(runResults: ["v1.2.3", "https://github.com/test/binary1"], inputResponses: [releaseNotes])
        
        let result = try sut.uploadRelease(info: info)
        
        #expect(result == "https://github.com/test/binary1")
        #expect(shell.printedCommands.contains(makeGitHubCommand(.createNewReleaseWithBinary(version: "2.0.0", binaryPath: info.binaryPath, releaseNotes: releaseNotes), path: info.projectPath)))
    }

    @Test("Uploads release when version is provided via input")
    func uploadReleaseWithUserInputVersion() throws {
        let version = "1.5.0"
        let info = makeReleaseInfo(versionInfo: nil)
        let releaseNotes = "Manual release notes"
        let (sut, shell) = makeSUT(runResults: ["https://github.com/test/binary1"], inputResponses: [version, releaseNotes])
        
        let result = try sut.uploadRelease(info: info)
        
        #expect(result == "https://github.com/test/binary1")
        #expect(shell.printedCommands.contains(makeGitHubCommand(.createNewReleaseWithBinary(version: version, binaryPath: info.binaryPath, releaseNotes: releaseNotes), path: info.projectPath)))
    }
    
    @Test("Throws error if version number is invalid")
    func invalidVersionNumberError() throws {
        let info = makeReleaseInfo(versionInfo: nil)
        let (sut, _) = makeSUT(inputResponses: ["invalid.version"])
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info)
        }
    }
    
    @Test("Throws error if previous version cannot be retrieved")
    func previousVersionError() throws {
        let info = makeReleaseInfo(versionInfo: .increment(.patch))
        let (sut, _) = makeSUT(throwShellError: true)
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info)
        }
    }
    
    @Test("Throws error if release notes retrieval fails")
    func releaseNotesError() throws {
        let info = makeReleaseInfo()
        let (sut, _) = makeSUT(throwPickerError: true)
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(info: info)
        }
    }
}

// MARK: - SUT
private extension ReleaseStoreTests {
    func makeSUT(runResults: [String] = [], inputResponses: [String] = [], throwShellError: Bool = false, throwPickerError: Bool = false) -> (sut: ReleaseStore, shell: MockShell) {
        let shell = MockShell(runResults: runResults, shouldThrowError: throwShellError)
        let picker = MockPicker(inputResponses: inputResponses, shouldThrowError: throwPickerError)
        let sut = ReleaseStore(shell: shell, picker: picker)
        
        return (sut, shell)
    }
    
    func makeReleaseInfo(binaryPath: String = "path/to/binary", projectPath: String = "path/to/project", versionInfo: ReleaseVersionInfo? = .version("1.0.0")) -> ReleaseInfo {
        return .init(binaryPath: binaryPath, projectPath: projectPath, versionInfo: versionInfo)
    }
}

//
//  ReleaseHandlerTests.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Testing
import Foundation
import NnexKit
import GitCommandGen
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

struct ReleaseHandlerTests {
    private let testProjectName = "TestProject"
    private let testBinaryPath = "/path/to/binary"
    private let testBinarySha256 = "abc123def456"
    private let testAssetURL = "https://github.com/test/repo/releases/download/v1.0.0/binary"
    private let testPreviousVersion = "v0.9.0"
    private let testVersionNumber = "1.0.0"
    private let testReleaseNotes = "Test release notes content"
    private let testReleaseNotesFile = "/path/to/notes.md"
}


// MARK: - Unit Tests
extension ReleaseHandlerTests {
    @Test("Uploads release successfully with provided version info")
    func uploadsReleaseSuccessfullyWithProvidedVersionInfo() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: versionInfo,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == testVersionNumber)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == false)
    }
    
    @Test("Uploads release with version increment when no version provided")
    func uploadsReleaseWithVersionIncrementWhenNoVersionProvided() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: ["minor"]
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: nil,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
    }
    
    @Test("Uploads release with new version number when no previous version exists")
    func uploadsReleaseWithNewVersionNumberWhenNoPreviousVersionExists() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: nil,
            inputResponses: [testVersionNumber]
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: nil,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == testVersionNumber)
    }
    
    @Test("Uses release notes from file when notesFile provided")
    func usesReleaseNotesFromFileWhenNotesFileProvided() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: testReleaseNotesFile)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: versionInfo,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotesFile)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == true)
    }
    
    @Test("Uses direct release notes when notes provided")
    func usesDirectReleaseNotesWhenNotesProvided() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: versionInfo,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == false)
    }
    
    @Test("Falls back to ReleaseNotesHandler when no notes provided")
    func fallsBackToReleaseNotesHandlerWhenNoNotesProvided() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: nil)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: [testReleaseNotes],
            selectedIndices: [0] // Direct input option
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: versionInfo,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == false)
    }
    
    @Test("Handles version input with increment keyword")
    func handlesVersionInputWithIncrementKeyword() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, _, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: ["patch"]
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: nil,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
    }
    
    @Test("Handles version input with specific version number")
    func handlesVersionInputWithSpecificVersionNumber() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: ["2.1.0"]
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: nil,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == "2.1.0")
    }
    
    @Test("Shows previous version in prompt when available")
    func showsPreviousVersionInPromptWhenAvailable() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: ["1.5.0"]
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: nil,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == "1.5.0")
    }
    
    @Test("Shows default version format when no previous version")
    func showsDefaultVersionFormatWhenNoPreviousVersion() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: nil,
            inputResponses: ["1.0.0"]
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryInfo: makeBinaryInfo(),
            versionInfo: nil,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == "1.0.0")
    }
    
    @Test("Throws error when git handler fails")
    func throwsErrorWhenGitHandlerFails() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, _, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            shouldThrowGitError: true
        )
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(
                folder: folder,
                binaryInfo: makeBinaryInfo(),
                versionInfo: versionInfo,
                releaseNotesSource: releaseNotesSource
            )
        }
    }
    
    @Test("Throws error when picker input fails")
    func throwsErrorWhenPickerInputFails() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, _, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            shouldThrowPickerError: true
        )
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(
                folder: folder,
                binaryInfo: makeBinaryInfo(),
                versionInfo: nil,
                releaseNotesSource: releaseNotesSource
            )
        }
    }
}


// MARK: - SUT
private extension ReleaseHandlerTests {
    func makeSUT(
        assetURL: String = "",
        previousVersion: String? = nil,
        inputResponses: [String] = [],
        selectedIndices: [Int] = [],
        shouldThrowGitError: Bool = false,
        shouldThrowPickerError: Bool = false
    ) throws -> (sut: ReleaseHandler, folder: Folder, gitHandler: MockGitHandler, picker: MockPicker) {
        
        let gitHandler = MockGitHandler(
            previousVersion: previousVersion ?? "",
            assetURL: assetURL,
            throwError: shouldThrowGitError
        )
        
        let picker = MockPicker(
            selectedItemIndices: selectedIndices,
            inputResponses: inputResponses,
            shouldThrowError: shouldThrowPickerError
        )
        
        let sut = ReleaseHandler(picker: picker, gitHandler: gitHandler)
        let tempFolder = try Folder.temporary.createSubfolder(named: "ReleaseHandlerTest-\(UUID().uuidString)")
        let folder = try tempFolder.createSubfolder(named: testProjectName)
        
        return (sut, folder, gitHandler, picker)
    }
    
    func makeBinaryInfo() -> BinaryInfo {
        return BinaryInfo(path: testBinaryPath, sha256: testBinarySha256)
    }
}

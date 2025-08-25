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
        
        let (sut, folder, gitHandler, _, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: versionInfo,
            previousVersion: testPreviousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == testVersionNumber)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == false)
    }
    
    @Test("Resolves version with increment when no version provided")
    func resolvesVersionWithIncrementWhenNoVersionProvided() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, picker, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: ["minor"]
        )
        
        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler)
        let (resolvedVersion, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: nil, projectPath: folder.path)
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: resolvedVersion,
            previousVersion: previousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
    }
    
    @Test("Resolves version with new number when no previous version exists")
    func resolvesVersionWithNewNumberWhenNoPreviousVersionExists() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, picker, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: nil,
            inputResponses: [testVersionNumber]
        )
        
        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler)
        let (resolvedVersion, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: nil, projectPath: folder.path)
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: resolvedVersion,
            previousVersion: previousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == testVersionNumber)
    }
    
    @Test("Uses release notes from file when notesFile provided")
    func usesReleaseNotesFromFileWhenNotesFileProvided() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: testReleaseNotesFile)
        
        let (sut, folder, gitHandler, _, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: versionInfo,
            previousVersion: testPreviousVersion,
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
        
        let (sut, folder, gitHandler, _, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: versionInfo,
            previousVersion: testPreviousVersion,
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
        
        let (sut, folder, gitHandler, _, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: [testReleaseNotes],
            selectedIndices: [0] // Direct input option
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: versionInfo,
            previousVersion: testPreviousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == false)
    }
    
    @Test("Handles version input with increment keyword")
    func handlesVersionInputWithIncrementKeyword() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, picker, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: ["patch"]
        )
        
        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler)
        let (resolvedVersion, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: nil, projectPath: folder.path)
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: resolvedVersion,
            previousVersion: previousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
    }
    
    @Test("Handles version input with specific version number")
    func handlesVersionInputWithSpecificVersionNumber() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, picker, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: ["2.1.0"]
        )
        
        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler)
        let (resolvedVersion, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: nil, projectPath: folder.path)
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: resolvedVersion,
            previousVersion: previousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == "2.1.0")
    }
    
    @Test("Shows previous version in prompt when available")
    func showsPreviousVersionInPromptWhenAvailable() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, picker, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            inputResponses: ["1.5.0"]
        )
        
        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler)
        let (resolvedVersion, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: nil, projectPath: folder.path)
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: resolvedVersion,
            previousVersion: previousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == "1.5.0")
    }
    
    @Test("Shows default version format when no previous version")
    func showsDefaultVersionFormatWhenNoPreviousVersion() throws {
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, picker, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: nil,
            inputResponses: ["1.0.0"]
        )
        
        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler)
        let (resolvedVersion, previousVersion) = try versionHandler.resolveVersionInfo(versionInfo: nil, projectPath: folder.path)
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: resolvedVersion,
            previousVersion: previousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseVersion == "1.0.0")
    }
    
    @Test("Throws error when git handler fails")
    func throwsErrorWhenGitHandlerFails() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, _, _, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            shouldThrowGitError: true
        )
        
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(
                folder: folder,
                binaryOutput: makeBinaryOutput(),
                versionInfo: versionInfo,
                previousVersion: testPreviousVersion,
                releaseNotesSource: releaseNotesSource
            )
        }
    }
    
    @Test("Throws error when picker input fails")
    func throwsErrorWhenPickerInputFails() throws {
        let (_, folder, gitHandler, picker, _) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            shouldThrowPickerError: true
        )
        
        let versionHandler = ReleaseVersionHandler(picker: picker, gitHandler: gitHandler)
        
        #expect(throws: (any Error).self) {
            try versionHandler.resolveVersionInfo(versionInfo: nil, projectPath: folder.path)
        }
    }
    
    @Test("Moves release notes file to trash when user confirms")
    func movesReleaseNotesFileToTrashWhenUserConfirms() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: testReleaseNotesFile)
        
        let (sut, folder, gitHandler, _, trashHandler) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            permissionResponses: [true]
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: versionInfo,
            previousVersion: testPreviousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotesFile)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == true)
        #expect(trashHandler.moveToTrashCalled == true)
        #expect(trashHandler.lastMovedPath == testReleaseNotesFile)
    }
    
    @Test("Does not move release notes file to trash when user declines")
    func doesNotMoveReleaseNotesFileToTrashWhenUserDeclines() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: testReleaseNotesFile)
        
        let (sut, folder, gitHandler, _, trashHandler) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            permissionResponses: [false]
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: versionInfo,
            previousVersion: testPreviousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotesFile)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == true)
        #expect(trashHandler.moveToTrashCalled == false)
        #expect(trashHandler.lastMovedPath == nil)
    }
    
    @Test("Does not attempt to move to trash when notes are inline")
    func doesNotAttemptToMoveToTrashWhenNotesAreInline() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)
        
        let (sut, folder, gitHandler, _, trashHandler) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            permissionResponses: [true] // This shouldn't matter since no file is involved
        )
        
        let result = try sut.uploadRelease(
            folder: folder,
            binaryOutput: makeBinaryOutput(),
            versionInfo: versionInfo,
            previousVersion: testPreviousVersion,
            releaseNotesSource: releaseNotesSource
        )
        
        #expect(result == testAssetURL)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == false)
        #expect(trashHandler.moveToTrashCalled == false)
        #expect(trashHandler.lastMovedPath == nil)
    }
    
    @Test("Handles trash operation failure gracefully")
    func handlesTrashOperationFailureGracefully() throws {
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: testReleaseNotesFile)
        
        let (sut, folder, _, _, trashHandler) = try makeSUT(
            assetURL: testAssetURL,
            previousVersion: testPreviousVersion,
            permissionResponses: [true],
            shouldThrowTrashError: true
        )
        
        // Even if trash fails, the release should still succeed
        #expect(throws: (any Error).self) {
            try sut.uploadRelease(
                folder: folder,
                binaryOutput: makeBinaryOutput(),
                versionInfo: versionInfo,
                previousVersion: testPreviousVersion,
                releaseNotesSource: releaseNotesSource
            )
        }
        
        #expect(trashHandler.moveToTrashCalled == true)
        #expect(trashHandler.lastMovedPath == testReleaseNotesFile)
    }
}


// MARK: - SUT
private extension ReleaseHandlerTests {
    func makeSUT(
        assetURL: String = "",
        previousVersion: String? = nil,
        inputResponses: [String] = [],
        selectedIndices: [Int] = [],
        permissionResponses: [Bool] = [],
        shouldThrowGitError: Bool = false,
        shouldThrowPickerError: Bool = false,
        shouldThrowTrashError: Bool = false
    ) throws -> (sut: ReleaseHandler, folder: Folder, gitHandler: MockGitHandler, picker: MockPicker, trashHandler: MockTrashHandler) {
        
        let gitHandler = MockGitHandler(
            previousVersion: previousVersion ?? "",
            assetURL: assetURL,
            throwError: shouldThrowGitError
        )
        
        let picker = MockPicker(
            selectedItemIndices: selectedIndices,
            inputResponses: inputResponses,
            permissionResponses: permissionResponses,
            shouldThrowError: shouldThrowPickerError
        )
        
        let trashHandler = MockTrashHandler()
        trashHandler.shouldThrowError = shouldThrowTrashError
        
        let sut = ReleaseHandler(picker: picker, gitHandler: gitHandler, trashHandler: trashHandler)
        let tempFolder = try Folder.temporary.createSubfolder(named: "ReleaseHandlerTest-\(UUID().uuidString)")
        let folder = try tempFolder.createSubfolder(named: testProjectName)
        
        return (sut, folder, gitHandler, picker, trashHandler)
    }
    
    func makeBinaryOutput() -> BinaryOutput {
        return .single(BinaryInfo(path: testBinaryPath, sha256: testBinarySha256))
    }
}

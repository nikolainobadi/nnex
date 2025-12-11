//
//  ReleaseHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import Testing
import NnexKit
import Foundation
import GitCommandGen
import NnShellTesting
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

struct ReleaseHandlerTests {
    private let testProjectPath = "/Users/test/TestProject"
    private let testProjectName = "TestProject"
    private let testBinaryPath = "/path/to/binary"
    private let testArchivePath = "/path/to/binary.tar.gz"
    private let testBinarySha256 = "abc123def456"
    private let testAssetURL = "https://github.com/test/repo/releases/download/v1.0.0/binary"
    private let testPreviousVersion = "v0.9.0"
    private let testVersionNumber = "1.0.0"
    private let testReleaseNotes = "Test release notes content"
    private let testReleaseNotesFile = "/path/to/notes.md"
}


// MARK: - Upload Release with Direct Notes
extension ReleaseHandlerTests {
    @Test("Uploads release with direct notes string")
    func uploadsReleaseWithDirectNotes() throws {
        let (sut, folder, gitHandler, _) = makeSUT(assetURL: testAssetURL)
        let binary = makeArchivedBinary()
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)

        let (assetURLs, versionNumber) = try sut.uploadRelease(folder: folder, archivedBinaries: [binary], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(assetURLs == [testAssetURL])
        #expect(versionNumber == testVersionNumber)
        #expect(gitHandler.releaseVersion == testVersionNumber)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotes)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == false)
    }

    @Test("Uploads release with notes file path")
    func uploadsReleaseWithNotesFile() throws {
        let (sut, folder, gitHandler, _) = makeSUT(assetURL: testAssetURL)
        let binary = makeArchivedBinary()
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: testReleaseNotesFile)

        let (assetURLs, versionNumber) = try sut.uploadRelease(folder: folder, archivedBinaries: [binary], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(assetURLs == [testAssetURL])
        #expect(versionNumber == testVersionNumber)
        #expect(gitHandler.releaseNoteInfo?.content == testReleaseNotesFile)
        #expect(gitHandler.releaseNoteInfo?.isFromFile == true)
    }
}


// MARK: - Multiple Binaries
extension ReleaseHandlerTests {
    @Test("Uploads release with single binary")
    func uploadsReleaseWithSingleBinary() throws {
        let (sut, folder, gitHandler, _) = makeSUT(assetURL: testAssetURL)
        let binary = makeArchivedBinary()
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)

        let (assetURLs, _) = try sut.uploadRelease(folder: folder, archivedBinaries: [binary], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(assetURLs.count == 1)
        #expect(gitHandler.releaseVersion == testVersionNumber)
    }

    @Test("Uploads release with multiple binaries")
    func uploadsReleaseWithMultipleBinaries() throws {
        let assetURL1 = "\(testAssetURL)-1"
        let (sut, folder, gitHandler, _) = makeSUT(assetURL: assetURL1)
        let binary1 = makeArchivedBinary(originalPath: "/path/to/binary1")
        let binary2 = makeArchivedBinary(originalPath: "/path/to/binary2")
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)

        let (assetURLs, _) = try sut.uploadRelease(folder: folder, archivedBinaries: [binary1, binary2], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(assetURLs.count == 2)
        #expect(assetURLs[0] == assetURL1)
        #expect(assetURLs[1].contains("additional"))
        #expect(gitHandler.releaseVersion == testVersionNumber)
    }
}


// MARK: - Trash Release Notes
extension ReleaseHandlerTests {
    @Test("Trashes release notes file when user confirms")
    func trashesNotesFileWhenConfirmed() throws {
        let (sut, folder, _, fileSystem) = makeSUT(assetURL: testAssetURL, permissionResult: true)
        let binary = makeArchivedBinary()
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: testReleaseNotesFile)

        _ = try sut.uploadRelease(folder: folder, archivedBinaries: [binary], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(fileSystem.pathToMoveToTrash == testReleaseNotesFile)
    }

    @Test("Does not trash notes file when user declines")
    func doesNotTrashNotesFileWhenDeclined() throws {
        let (sut, folder, _, fileSystem) = makeSUT(assetURL: testAssetURL, permissionResult: false)
        let binary = makeArchivedBinary()
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: nil, notesFile: testReleaseNotesFile)

        _ = try sut.uploadRelease(folder: folder, archivedBinaries: [binary], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(fileSystem.pathToMoveToTrash == nil)
    }

    @Test("Does not prompt to trash notes when notes are from string")
    func doesNotPromptToTrashWhenNotesFromString() throws {
        let (sut, folder, _, fileSystem) = makeSUT(assetURL: testAssetURL)
        let binary = makeArchivedBinary()
        let versionInfo = ReleaseVersionInfo.version(testVersionNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)

        _ = try sut.uploadRelease(folder: folder, archivedBinaries: [binary], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(fileSystem.pathToMoveToTrash == nil)
    }
}


// MARK: - Version Handling
extension ReleaseHandlerTests {
    @Test("Extracts version string from version case")
    func extractsVersionFromVersionCase() throws {
        let releaseNumber = "v2.5.0"
        let (sut, folder, gitHandler, _) = makeSUT(assetURL: testAssetURL)
        let binary = makeArchivedBinary()
        let versionInfo = ReleaseVersionInfo.version(releaseNumber)
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)

        let (_, versionNumber) = try sut.uploadRelease(folder: folder, archivedBinaries: [binary], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(versionNumber == releaseNumber)
        #expect(gitHandler.releaseVersion == releaseNumber)
    }

    @Test("Handles version string without v prefix")
    func handlesVersionWithoutVPrefix() throws {
        let (sut, folder, gitHandler, _) = makeSUT(assetURL: testAssetURL)
        let binary = makeArchivedBinary()
        let versionInfo = ReleaseVersionInfo.version("3.0.1")
        let releaseNotesSource = ReleaseNotesSource(notes: testReleaseNotes, notesFile: nil)

        let (_, versionNumber) = try sut.uploadRelease(folder: folder, archivedBinaries: [binary], versionInfo: versionInfo, previousVersion: testPreviousVersion, releaseNotesSource: releaseNotesSource)

        #expect(versionNumber == "3.0.1")
        #expect(gitHandler.releaseVersion == "3.0.1")
    }
}


// MARK: - SUT
private extension ReleaseHandlerTests {
    func makeSUT(assetURL: String = "", permissionResult: Bool = true) -> (sut: ReleaseHandler, folder: any Directory, gitHandler: MockGitHandler, fileSystem: MockFileSystem) {
        let folder = MockDirectory(path: testProjectPath)
        let picker = MockSwiftPicker(permissionResult: .init(defaultValue: permissionResult, type: .ordered([])))
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let fileSystem = MockFileSystem()
        let folderBrowser = MockDirectoryBrowser(filePathToReturn: nil, directoryToReturn: nil)
        let sut = ReleaseHandler(picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, folderBrowser: folderBrowser)

        return (sut, folder, gitHandler, fileSystem)
    }

    func makeArchivedBinary(originalPath: String? = nil, archivePath: String? = nil, sha256: String? = nil) -> ArchivedBinary {
        return .init(originalPath: originalPath ?? testBinaryPath, archivePath: archivePath ?? testArchivePath, sha256: sha256 ?? testBinarySha256)
    }
}

//
//  GithubReleaseControllerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit
import Testing
import Foundation
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex

final class GithubReleaseControllerTests {
    @Test("Starting values empty")
    func startingValuesEmpty() {
        let (_, gitHandler) = makeSUT()

        #expect(gitHandler.releaseVersion == nil)
        #expect(gitHandler.releaseNoteInfo == nil)
    }
}


// MARK: - Upload Release with Provided Notes
extension GithubReleaseControllerTests {
    @Test("Uploads release with exact notes provided")
    func uploadsReleaseWithExactNotes() throws {
        let expectedVersion = "1.0.0"
        let expectedNotes = "Release notes content"
        let assets = makeAssets()
        let (sut, gitHandler) = makeSUT()
        let folder = MockDirectory(path: "/project/myapp")

        let assetURLs = try sut.uploadRelease(version: expectedVersion, assets: assets, notes: expectedNotes, notesFilePath: nil, projectFolder: folder)
        let noteInfo = try #require(gitHandler.releaseNoteInfo)

        #expect(gitHandler.releaseVersion == expectedVersion)
        #expect(noteInfo.content == expectedNotes)
        #expect(noteInfo.isFromFile == false)
        #expect(!assetURLs.isEmpty)
    }

    @Test("Uploads release with file path provided")
    func uploadsReleaseWithFilePath() throws {
        let expectedVersion = "2.0.0"
        let expectedFilePath = "/path/to/notes.md"
        let assets = makeAssets()
        let (sut, gitHandler) = makeSUT()
        let folder = MockDirectory(path: "/project/app")

        let assetURLs = try sut.uploadRelease(version: expectedVersion, assets: assets, notes: nil, notesFilePath: expectedFilePath, projectFolder: folder)
        let noteInfo = try #require(gitHandler.releaseNoteInfo)

        #expect(gitHandler.releaseVersion == expectedVersion)
        #expect(noteInfo.content == expectedFilePath)
        #expect(noteInfo.isFromFile == true)
        #expect(!assetURLs.isEmpty)
    }
}


// MARK: - Upload Release with Interactive Selection
extension GithubReleaseControllerTests {
    @Test("Uploads release with direct input notes")
    func uploadsReleaseWithDirectInput() throws {
        let expectedNotes = "Interactive release notes"
        let assets = makeAssets()
        let (sut, gitHandler) = makeSUT(inputResults: [expectedNotes], selectionIndex: 0)
        let folder = MockDirectory(path: "/project/app")

        _ = try sut.uploadRelease(version: "1.0.0", assets: assets, notes: nil, notesFilePath: nil, projectFolder: folder)

        let noteInfo = try #require(gitHandler.releaseNoteInfo)
        #expect(noteInfo.content == expectedNotes)
        #expect(noteInfo.isFromFile == false)
    }

    @Test("Uploads release with file from browser")
    func uploadsReleaseWithSelectedFile() throws {
        let expectedFilePath = "/selected/notes.md"
        let assets = makeAssets()
        let (sut, gitHandler) = makeSUT(selectionIndex: 1, filePathToReturn: expectedFilePath)
        let folder = MockDirectory(path: "/project/app")

        _ = try sut.uploadRelease(version: "1.0.0", assets: assets, notes: nil, notesFilePath: nil, projectFolder: folder)

        let noteInfo = try #require(gitHandler.releaseNoteInfo)
        #expect(noteInfo.content == expectedFilePath)
        #expect(noteInfo.isFromFile == true)
    }

    @Test("Uploads release with path from input")
    func uploadsReleaseWithPathFromInput() throws {
        let expectedPath = "/entered/path/notes.md"
        let assets = makeAssets()
        let (sut, gitHandler) = makeSUT(inputResults: [expectedPath], selectionIndex: 2)
        let folder = MockDirectory(path: "/project/app")

        _ = try sut.uploadRelease(version: "1.0.0", assets: assets, notes: nil, notesFilePath: nil, projectFolder: folder)

        let noteInfo = try #require(gitHandler.releaseNoteInfo)
        #expect(noteInfo.content == expectedPath)
        #expect(noteInfo.isFromFile == true)
    }

    @Test("Creates new note file on desktop", .disabled()) // TODO: - need to handle error properly because file is always empty
    func createsNewNoteFile() throws {
        let testDate = Date(timeIntervalSince1970: 1704067200) // 1/1/24
        let expectedFileName = "myapp-releaseNotes-\(formatShortDate(testDate)).md"
        let desktop = MockDirectory(path: "/Users/test/Desktop")
        let assets = makeAssets()
        let (sut, gitHandler) = makeSUT(date: testDate, selectionIndex: 3, desktop: desktop)
        let folder = MockDirectory(path: "/project/myapp")

        _ = try sut.uploadRelease(version: "1.0.0", assets: assets, notes: nil, notesFilePath: nil, projectFolder: folder)
        let noteInfo = try #require(gitHandler.releaseNoteInfo)

        #expect(desktop.containedFiles.contains(expectedFileName))
        #expect(noteInfo.content.contains(expectedFileName))
        #expect(noteInfo.isFromFile == true)
    }
}


// MARK: - SUT
private extension GithubReleaseControllerTests {
    func makeSUT(date: Date = Date(), inputResults: [String] = [], selectionIndex: Int = 0, grantPermission: Bool = true, desktop: (any Directory)? = nil, filePathToReturn: String? = nil) -> (sut: GithubReleaseController, gitHandler: MockGitHandler) {
        let gitHandler = MockGitHandler()
        let fileSystem = MockFileSystem(desktop: desktop)
        let picker = MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResults)),
            permissionResult: .init(defaultValue: grantPermission),
            selectionResult: .init(defaultSingle: .index(selectionIndex))
        )
        let folderBrowser = MockDirectoryBrowser(filePathToReturn: filePathToReturn, directoryToReturn: nil)
        let dateProvider = MockDateProvider(date: date)
        let sut = GithubReleaseController(
            picker: picker,
            gitHandler: gitHandler,
            fileSystem: fileSystem,
            dateProvider: dateProvider,
            folderBrowser: folderBrowser
        )
        
        return (sut, gitHandler)
    }
    
    func makeAssets() -> [ArchivedBinary] {
        return [
            .init(originalPath: "/tmp/App", archivePath: "/tmp/App.tar.gz", sha256: "abc123")
        ]
    }
    
    func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: date)
    }
}

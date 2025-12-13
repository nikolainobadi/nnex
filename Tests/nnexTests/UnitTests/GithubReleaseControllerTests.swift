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
    @Test("Uploads release using provided notes content")
    func uploadReleaseWithDirectNotes() throws {
        let project = MockDirectory(path: "/project")
        let gitHandler = MockGitHandler(assetURL: "asset-url")
        let (sut, git, _, _, _, projectDir) = makeSUT(projectDirectory: project, gitHandler: gitHandler)
        let assets = makeAssets()
        
        let urls = try sut.uploadRelease(version: "2.0.0", assets: assets, notes: "Release body", notesFilePath: nil, projectFolder: projectDir)
        
        #expect(urls.count == assets.count)
        #expect(git.releaseVersion == "2.0.0")
        #expect(git.releaseNoteInfo?.content == "Release body")
        #expect(git.releaseNoteInfo?.isFromFile == false)
    }
    
    @Test("Uploads release using provided notes file path")
    func uploadReleaseWithNotesFilePath() throws {
        let project = MockDirectory(path: "/project")
        let gitHandler = MockGitHandler(assetURL: "asset-url")
        let filePath = "/notes/release.md"
        let (sut, git, _, _, _, projectDir) = makeSUT(projectDirectory: project, gitHandler: gitHandler)
        
        _ = try sut.uploadRelease(version: "1.1.0", assets: makeAssets(), notes: nil, notesFilePath: filePath, projectFolder: projectDir)
        
        #expect(git.releaseVersion == "1.1.0")
        #expect(git.releaseNoteInfo?.content == filePath)
        #expect(git.releaseNoteInfo?.isFromFile == true)
    }
    
    @Test("Prompts for release notes when selecting direct entry")
    func uploadReleaseWithPromptedNotes() throws {
        let project = MockDirectory(path: "/project")
        let inputNotes = "Typed release notes"
        let picker = GithubReleaseControllerTests.makePicker(inputResults: [inputNotes], selectionIndex: 0)
        let (sut, git, _, _, _, projectDir) = makeSUT(projectDirectory: project, picker: picker)
        
        _ = try sut.uploadRelease(version: "0.9.0", assets: makeAssets(), notes: nil, notesFilePath: nil, projectFolder: projectDir)
        
        #expect(git.releaseNoteInfo?.content == inputNotes)
        #expect(git.releaseNoteInfo?.isFromFile == false)
    }
    
    @Test("Browses for notes file when selecting file option")
    func uploadReleaseSelectingFile() throws {
        let project = MockDirectory(path: "/project")
        let notesFilePath = "/path/to/notes.md"
        let picker = GithubReleaseControllerTests.makePicker(selectionIndex: 1)
        let folderBrowser = MockDirectoryBrowser(filePathToReturn: notesFilePath, directoryToReturn: nil)
        let (sut, git, _, _, _, projectDir) = makeSUT(projectDirectory: project, picker: picker, folderBrowser: folderBrowser)
        
        _ = try sut.uploadRelease(version: "3.0.0", assets: makeAssets(), notes: nil, notesFilePath: nil, projectFolder: projectDir)
        
        #expect(git.releaseNoteInfo?.content == notesFilePath)
        #expect(git.releaseNoteInfo?.isFromFile == true)
    }
    
    @Test("Accepts manual file path when selecting fromPath option")
    func uploadReleaseSelectingManualPath() throws {
        let project = MockDirectory(path: "/project")
        let manualPath = "/manual/notes.md"
        let picker = GithubReleaseControllerTests.makePicker(inputResults: [manualPath], selectionIndex: 2)
        let (sut, git, _, _, _, projectDir) = makeSUT(projectDirectory: project, picker: picker)
        
        _ = try sut.uploadRelease(version: "4.0.0", assets: makeAssets(), notes: nil, notesFilePath: nil, projectFolder: projectDir)
        
        #expect(git.releaseNoteInfo?.content == manualPath)
        #expect(git.releaseNoteInfo?.isFromFile == true)
    }
    
    @Test("Throws when newly created notes file remains empty")
    func uploadReleaseCreateFileEmptyThrows() {
        let desktop = MockDirectory(path: "/Users/Home/Desktop")
        let fileSystem = MockFileSystem(directoryMap: [desktop.path: desktop], desktop: desktop)
        let project = MockDirectory(path: "/project")
        let date = Date(timeIntervalSince1970: 0) // 1/1/70 -> 1-1-70
        let picker = GithubReleaseControllerTests.makePicker(selectionIndex: 3, permissionResults: [true, true])
        let (sut, _, _, fs, _, projectDir) = makeSUT(projectDirectory: project, picker: picker, fileSystem: fileSystem, date: date)
        
        let expectedFileName = "\(project.name)-releaseNotes-\(formatShortDate(date)).md"
        let expectedPath = desktop.path.appendingPathComponent(expectedFileName)
        let assets = makeAssets()
        
        #expect(throws: ReleaseNotesError.emptyFileAfterRetry(filePath: expectedPath)) {
            _ = try sut.uploadRelease(version: "1.0.0", assets: assets, notes: nil, notesFilePath: nil, projectFolder: projectDir)
        }
        
        #expect(desktop.containsFile(named: expectedFileName))
        #expect(fs.capturedPaths.contains(desktop.path))
    }
}


// MARK: - SUT
private extension GithubReleaseControllerTests {
    func makeSUT(
        projectDirectory: MockDirectory,
        picker: MockSwiftPicker = GithubReleaseControllerTests.makePicker(),
        gitHandler: MockGitHandler = MockGitHandler(),
        fileSystem: MockFileSystem? = nil,
        folderBrowser: MockDirectoryBrowser? = nil,
        date: Date = Date()
    ) -> (sut: GithubReleaseController, gitHandler: MockGitHandler, picker: MockSwiftPicker, fileSystem: MockFileSystem, folderBrowser: MockDirectoryBrowser, project: MockDirectory) {
        let fileSystem = fileSystem ?? MockFileSystem()
        let folderBrowser = folderBrowser ?? MockDirectoryBrowser(filePathToReturn: nil, directoryToReturn: nil)
        let dateProvider = MockDateProvider(date: date)
        let sut = GithubReleaseController(
            picker: picker,
            gitHandler: gitHandler,
            fileSystem: fileSystem,
            dateProvider: dateProvider,
            folderBrowser: folderBrowser
        )
        
        return (sut, gitHandler, picker, fileSystem, folderBrowser, projectDirectory)
    }
    
    func makeAssets() -> [ArchivedBinary] {
        return [
            ArchivedBinary(originalPath: "/tmp/App", archivePath: "/tmp/App.tar.gz", sha256: "abc123")
        ]
    }
    
    func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: date)
    }
}


// MARK: - Picker
private extension GithubReleaseControllerTests {
    static func makePicker(inputResults: [String] = [], selectionIndex: Int = 0, permissionResults: [Bool] = []) -> MockSwiftPicker {
        MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResults)),
            permissionResult: .init(type: .ordered(permissionResults)),
            selectionResult: .init(defaultSingle: .index(selectionIndex))
        )
    }
}

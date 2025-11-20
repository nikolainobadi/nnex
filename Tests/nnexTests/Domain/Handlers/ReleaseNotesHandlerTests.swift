//
//  ReleaseNotesHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import Testing
import Foundation
import NnShellKit
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

struct ReleaseNotesHandlerTests {
    private let projectName = "TestProject"
    private let testNotes = "Test release notes content"
    private let testFilePath = "/path/to/notes.md"
    private let testDate = Date(timeIntervalSince1970: 1691683200) // 2023-08-10
}


// MARK: - Unit Tests
extension ReleaseNotesHandlerTests {
    @Test("Returns direct input when user provides notes directly")
    func returnsDirectInput() throws {
        let sut = makeSUT(selectedOption: .direct, inputResponses: [testNotes]).sut
        let result = try sut.getReleaseNoteInfo()
        
        #expect(result.content == testNotes)
        #expect(result.isFromFile == false)
    }
    
    @Test("Returns file path when user provides existing file path")
    func returnsFilePathInput() throws {
        let sut = makeSUT(selectedOption: .fromPath, inputResponses: [testFilePath]).sut
        let result = try sut.getReleaseNoteInfo()
        
        #expect(result.content == testFilePath)
        #expect(result.isFromFile == true)
    }
    
    @Test("Creates file with correct timestamp when user chooses to create new file")
    func createsFileWithTimestamp() throws {
        let expectedFileName = "\(projectName)-releaseNotes-8-10-23.md"
        let (sut, fileSystem) = makeSUT(selectedOption: .createFile, permissionResponses: [true], fileContent: testNotes)
        let result = try sut.getReleaseNoteInfo()
        
        #expect(fileSystem.createdFileName == expectedFileName)
        #expect(result.isFromFile == true)
        #expect(result.content == fileSystem.createdFilePath)
    }
    
    @Test("Handles non-empty file content successfully")
    func handlesNonEmptyFileContent() throws {
        let (sut, fileSystem) = makeSUT(selectedOption: .createFile, permissionResponses: [true], fileContent: testNotes)
        let result = try sut.getReleaseNoteInfo()
        
        #expect(result.content == fileSystem.createdFilePath)
        #expect(result.isFromFile == true)
    }
    
    @Test("Throws error when file remains empty after retry")
    func throwsErrorForPersistentlyEmptyFile() throws {
        let sut = makeSUT(
            selectedOption: .createFile,
            permissionResponses: [true, true],
            fileContent: ""
        ).sut
        
        #expect(throws: (any Error).self) {
            try sut.getReleaseNoteInfo()
        }
    }
    
    @Test("Handles user cancellation during file confirmation")
    func handlesUserCancellationDuringFileConfirmation() throws {
        let sut = makeSUT(
            selectedOption: .createFile,
            shouldThrowPickerError: true
        ).sut
        
        #expect(throws: (any Error).self) {
            try sut.getReleaseNoteInfo()
        }
    }
    
    @Test("Handles user cancellation during retry confirmation")
    func handlesUserCancellationDuringRetryConfirmation() throws {
        let sut = makeSUT(
            selectedOption: .createFile,
            permissionResponses: [true],
            fileContent: "",
            shouldThrowPickerError: true
        ).sut
        
        #expect(throws: (any Error).self) {
            try sut.getReleaseNoteInfo()
        }
    }
    
    @Test("Handles picker selection cancellation")
    func handlesPickerSelectionCancellation() throws {
        let sut = makeSUT(shouldThrowPickerError: true).sut
        
        #expect(throws: (any Error).self) {
            try sut.getReleaseNoteInfo()
        }
    }
}

// MARK: - SUT
private extension ReleaseNotesHandlerTests {
    func makeSUT(
        selectedOption: ReleaseNotesHandler.NoteContentType = .direct,
        inputResponses: [String] = [],
        permissionResponses: [Bool] = [],
        fileContent: String = "",
        shouldThrowPickerError: Bool = false
    ) -> (sut: ReleaseNotesHandler, fileSystem: MockFileSystemProvider) {
        let picker = MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResponses)),
            permissionResult: .init(type: .ordered(permissionResponses)),
            selectionResult: .init(defaultSingle: .index(selectedOption.index))
        )
        let fileSystem = MockFileSystemProvider(fileContent: fileContent)
        let dateProvider = MockDateProvider(date: testDate)
        let fileUtility = ReleaseNotesFileUtility(picker: picker, fileSystem: fileSystem, dateProvider: dateProvider)
        let sut = ReleaseNotesHandler(picker: picker, projectName: projectName, fileUtility: fileUtility)
        
        return (sut, fileSystem)
    }
}


// MARK: - Extensions Dependencies
private extension ReleaseNotesHandler.NoteContentType {
    var index: Int {
        switch self {
        case .direct:
            return 0
        case .fromPath:
            return 1
        case .createFile:
            return 2
        }
    }
}


// MARK: - Helper Functions
private func deleteFolderContents(_ folder: Folder) {
    try? folder.delete()
}

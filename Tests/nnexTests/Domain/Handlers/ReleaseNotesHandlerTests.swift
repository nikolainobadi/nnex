//
//  ReleaseNotesHandlerTests.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Testing
import Foundation
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
        let (sut, _, _) = makeSUT(
            selectedOption: .direct,
            inputResponses: [testNotes]
        )
        
        let result = try sut.getReleaseNoteInfo()
        
        #expect(result.content == testNotes)
        #expect(result.isFromFile == false)
    }
    
    @Test("Returns file path when user provides existing file path")
    func returnsFilePathInput() throws {
        let (sut, _, _) = makeSUT(
            selectedOption: .fromPath,
            inputResponses: [testFilePath]
        )
        
        let result = try sut.getReleaseNoteInfo()
        
        #expect(result.content == testFilePath)
        #expect(result.isFromFile == true)
    }
    
    @Test("Creates file with correct timestamp when user chooses to create new file")
    func createsFileWithTimestamp() throws {
        let expectedFileName = "\(projectName)-releaseNotes-8-10-23.md"
        let (sut, _, fileSystem) = makeSUT(
            selectedOption: .createFile,
            permissionResponses: [true],
            fileContent: testNotes
        )
        
        let result = try sut.getReleaseNoteInfo()
        
        #expect(fileSystem.createdFileName == expectedFileName)
        #expect(result.isFromFile == true)
        #expect(result.content == fileSystem.createdFilePath)
    }
    
    @Test("Handles non-empty file content successfully")
    func handlesNonEmptyFileContent() throws {
        let (sut, _, fileSystem) = makeSUT(
            selectedOption: .createFile,
            permissionResponses: [true],
            fileContent: testNotes
        )
        
        let result = try sut.getReleaseNoteInfo()
        
        #expect(result.content == fileSystem.createdFilePath)
        #expect(result.isFromFile == true)
    }
    
    @Test("Throws error when file remains empty after retry")
    func throwsErrorForPersistentlyEmptyFile() throws {
        let (sut, _, _) = makeSUT(
            selectedOption: .createFile,
            permissionResponses: [true, true], // Confirms file creation, then confirms retry
            fileContent: "" // File remains empty
        )
        
        #expect(throws: (any Error).self) {
            try sut.getReleaseNoteInfo()
        }
    }
    
    @Test("Handles user cancellation during file confirmation")
    func handlesUserCancellationDuringFileConfirmation() throws {
        let (sut, _, _) = makeSUT(
            selectedOption: .createFile,
            permissionResponses: [], // No responses provided, will cause picker to throw
            shouldThrowPickerError: true
        )
        
        #expect(throws: (any Error).self) {
            try sut.getReleaseNoteInfo()
        }
    }
    
    @Test("Handles user cancellation during retry confirmation")
    func handlesUserCancellationDuringRetryConfirmation() throws {
        let (sut, _, _) = makeSUT(
            selectedOption: .createFile,
            permissionResponses: [true], // First confirmation succeeds, but no retry confirmation
            fileContent: "",
            shouldThrowPickerError: true
        )
        
        #expect(throws: (any Error).self) {
            try sut.getReleaseNoteInfo()
        }
    }
    
    @Test("Handles picker selection cancellation")
    func handlesPickerSelectionCancellation() throws {
        let (sut, _, _) = makeSUT(shouldThrowPickerError: true)
        
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
    ) -> (sut: ReleaseNotesHandler, picker: MockPicker, fileSystem: MockFileSystemProvider) {
        
        let picker = MockPicker(
            selectedItemIndices: [selectedOption.index],
            inputResponses: inputResponses,
            permissionResponses: permissionResponses,
            shouldThrowError: shouldThrowPickerError
        )
        
        let fileSystem = MockFileSystemProvider(fileContent: fileContent)
        let dateProvider = MockDateProvider(date: testDate)
        
        let sut = ReleaseNotesHandler(
            picker: picker,
            projectName: projectName,
            fileSystem: fileSystem,
            dateProvider: dateProvider
        )
        
        return (sut, picker, fileSystem)
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

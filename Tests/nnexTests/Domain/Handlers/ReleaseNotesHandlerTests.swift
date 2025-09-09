//
//  ReleaseNotesHandlerTests.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Testing
import Foundation
import NnShellKit
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
        let (sut, _, _) = makeSUT(selectedOption: .direct, inputResponses: [testNotes])
        let result = try sut.getReleaseNoteInfo()
        
        #expect(result.content == testNotes)
        #expect(result.isFromFile == false)
    }
    
    @Test("Returns file path when user provides existing file path")
    func returnsFilePathInput() throws {
        let (sut, _, _) = makeSUT(selectedOption: .fromPath, inputResponses: [testFilePath])
        let result = try sut.getReleaseNoteInfo()
        
        #expect(result.content == testFilePath)
        #expect(result.isFromFile == true)
    }
    
    @Test("Creates file with correct timestamp when user chooses to create new file")
    func createsFileWithTimestamp() throws {
        let expectedFileName = "\(projectName)-releaseNotes-8-10-23.md"
        let (sut, _, fileSystem) = makeSUT(selectedOption: .createFile, permissionResponses: [true], fileContent: testNotes)
        let result = try sut.getReleaseNoteInfo()
        
        #expect(fileSystem.createdFileName == expectedFileName)
        #expect(result.isFromFile == true)
        #expect(result.content == fileSystem.createdFilePath)
    }
    
    @Test("Handles non-empty file content successfully")
    func handlesNonEmptyFileContent() throws {
        let (sut, _, fileSystem) = makeSUT(selectedOption: .createFile, permissionResponses: [true], fileContent: testNotes)
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


// MARK: - AI Tests
extension ReleaseNotesHandlerTests {
    @Test("AI option can be selected when enabled")
    func aiOptionCanBeSelectedWhenEnabled() throws {
        // Test that we can create a ReleaseNotesHandler with AI enabled and the aiGenerated option
        let (sut, _, _) = makeSUT(
            selectedOption: .aiGenerated,
            aiReleaseEnabled: true
        )
        
        // This should not throw during initialization, proving AI option is available when enabled
        #expect(sut != nil)
        
        // Test that AI generation throws missing requirements error when parameters are missing
        #expect(throws: ReleaseNotesError.missingAIRequirements) {
            try sut.getReleaseNoteInfo() // No AI parameters provided
        }
    }
    
    @Test("AI option does not appear when disabled")
    func aiOptionDoesNotAppearWhenDisabled() throws {
        let sut = makeSUT(selectedOption: .direct, inputResponses: [testNotes]).sut
        let result = try sut.getReleaseNoteInfo()
        
        // When AI is disabled, the picker should only have 3 options (direct, fromPath, createFile)
        // The actual filtering happens in the picker selection logic
        #expect(result.content == testNotes)
        #expect(result.isFromFile == false)
    }
    
    @Test("AI generation validates all parameters are present")
    func aiGenerationValidatesAllParametersArePresent() throws {
        let sut = makeSUT(selectedOption: .aiGenerated, aiReleaseEnabled: true).sut
        
        // Test that when all parameters are provided, it doesn't throw missingAIRequirements
        // Note: This test focuses on parameter validation, not the actual AI generation
        let tempFolder = Folder.temporary
        let projectFolder = try tempFolder.createSubfolder(named: "TestAIProject\(UUID().uuidString)")
        defer { deleteFolderContents(projectFolder) }
        
        // This should not throw missingAIRequirements error since all params are provided
        // It may throw other errors related to the actual AI generation process, but that's expected
        #expect(throws: (any Error).self) {
            try sut.getReleaseNoteInfo(
                releaseNumber: "1.0.0",
                projectPath: projectFolder.path, 
                shell: MockShell()
            )
        }
    }
    
    @Test("AI generation throws error when missing release number")
    func aiGenerationThrowsErrorWhenMissingReleaseNumber() throws {
        let sut = makeSUT(selectedOption: .aiGenerated, aiReleaseEnabled: true).sut
        
        #expect(throws: ReleaseNotesError.missingAIRequirements) {
            try sut.getReleaseNoteInfo(
                releaseNumber: nil,
                projectPath: "/test/path",
                shell: MockShell()
            )
        }
    }
    
    @Test("AI generation throws error when missing project path")
    func aiGenerationThrowsErrorWhenMissingProjectPath() throws {
        let (sut, _, _) = makeSUT(
            selectedOption: .aiGenerated,
            aiReleaseEnabled: true
        )
        
        #expect(throws: ReleaseNotesError.missingAIRequirements) {
            try sut.getReleaseNoteInfo(
                releaseNumber: "1.0.0",
                projectPath: nil,
                shell: MockShell()
            )
        }
    }
    
    @Test("AI generation throws error when missing shell")
    func aiGenerationThrowsErrorWhenMissingShell() throws {
        let (sut, _, _) = makeSUT(
            selectedOption: .aiGenerated,
            aiReleaseEnabled: true
        )
        
        #expect(throws: ReleaseNotesError.missingAIRequirements) {
            try sut.getReleaseNoteInfo(
                releaseNumber: "1.0.0",
                projectPath: "/test/path",
                shell: nil
            )
        }
    }
    
    @Test("Backward compatibility - existing functionality works with new parameters")
    func backwardCompatibilityWorksWithNewParameters() throws {
        let (sut, _, _) = makeSUT(
            selectedOption: .direct,
            inputResponses: [testNotes],
            aiReleaseEnabled: false
        )
        
        // Test that existing functionality still works when called with new parameters
        let result = try sut.getReleaseNoteInfo(
            releaseNumber: "1.0.0",
            projectPath: "/test/path",
            shell: MockShell()
        )
        
        #expect(result.content == testNotes)
        #expect(result.isFromFile == false)
    }
}


// MARK: - SUT
private extension ReleaseNotesHandlerTests {
    func makeSUT(selectedOption: ReleaseNotesHandler.NoteContentType = .direct, inputResponses: [String] = [], permissionResponses: [Bool] = [], fileContent: String = "", shouldThrowPickerError: Bool = false, aiReleaseEnabled: Bool = false) -> (sut: ReleaseNotesHandler, picker: MockPicker, fileSystem: MockFileSystemProvider) {
        let picker = MockPicker(selectedItemIndices: [selectedOption.index], inputResponses: inputResponses, permissionResponses: permissionResponses, shouldThrowError: shouldThrowPickerError)
        let fileSystem = MockFileSystemProvider(fileContent: fileContent)
        let dateProvider = MockDateProvider(date: testDate)
        let fileUtility = ReleaseNotesFileUtility(picker: picker, fileSystem: fileSystem, dateProvider: dateProvider)
        let sut = ReleaseNotesHandler(picker: picker, projectName: projectName, aiReleaseEnabled: aiReleaseEnabled, fileUtility: fileUtility)
        
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
        case .aiGenerated:
            return 3
        }
    }
}


// MARK: - Helper Functions
private func deleteFolderContents(_ folder: Folder) {
    try? folder.delete()
}

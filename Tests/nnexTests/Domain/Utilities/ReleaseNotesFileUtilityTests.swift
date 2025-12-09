////
////  ReleaseNotesFileUtilityTests.swift
////  nnex
////
////  Created by Nikolai Nobadi on 9/9/25.
////
//
//import Testing
//import Foundation
//import SwiftPickerTesting
//import NnexSharedTestHelpers
//@testable import nnex
//
//struct ReleaseNotesFileUtilityTests {
//    private let projectName = "TestProject"
//    private let version = "1.2.3"
//    private let testDate = Date(timeIntervalSince1970: 1691683200) // 2023-08-10
//    private let testContent = "Test release notes content"
//}
//
//
//// MARK: - createAndOpenNewNoteFile Tests
//extension ReleaseNotesFileUtilityTests {
//    @Test("Creates file with correct timestamp format")
//    func createsFileWithTimestamp() throws {
//        let (sut, fileSystem) = makeSUT()
//
//        _ = try sut.createAndOpenNewNoteFile(projectName: projectName)
//        
//        let expectedFileName = "\(projectName)-releaseNotes-8-10-23.md"
//        #expect(fileSystem.createdFileName == expectedFileName)
//        #expect(fileSystem.createdFilePath.contains("Desktop"))
//        #expect(fileSystem.createdFilePath.hasSuffix(expectedFileName))
//    }
//    
//    @Test("Returns file with correct path")
//    func returnsFileWithCorrectPath() throws {
//        let (sut, fileSystem) = makeSUT()
//
//        let file = try sut.createAndOpenNewNoteFile(projectName: projectName)
//        
//        #expect(file.path == fileSystem.createdFilePath)
//    }
//}
//
//
//// MARK: - createVersionedNoteFile Tests
//extension ReleaseNotesFileUtilityTests {
//    @Test("Creates versioned file with correct name")
//    func createsVersionedFile() throws {
//        let (sut, fileSystem) = makeSUT()
//
//        _ = try sut.createVersionedNoteFile(projectName: projectName, version: version)
//        
//        let expectedFileName = "\(projectName)-releaseNotes-v\(version).md"
//        #expect(fileSystem.createdFileName == expectedFileName)
//        #expect(fileSystem.createdFilePath.contains("Desktop"))
//        #expect(fileSystem.createdFilePath.hasSuffix(expectedFileName))
//    }
//    
//    @Test("Returns versioned file with correct path")
//    func returnsVersionedFileWithCorrectPath() throws {
//        let (sut, fileSystem) = makeSUT()
//
//        let file = try sut.createVersionedNoteFile(projectName: projectName, version: version)
//        
//        #expect(file.path == fileSystem.createdFilePath)
//    }
//}
//
//
//// MARK: - validateAndConfirmNoteFile Tests
//extension ReleaseNotesFileUtilityTests {
//    @Test("Returns file path when file has content")
//    func returnsFilePathWithContent() throws {
//        let sut = makeSUT(fileContent: testContent, permissionResponses: [true]).sut
//        let file = MockFile(path: "/test/path.md", content: testContent)
//        let result = try sut.validateAndConfirmNoteFile(file)
//        
//        #expect(result.content == file.path)
//        #expect(result.isFromFile == true)
//    }
//    
//    @Test("Handles empty file with successful retry")
//    func handlesEmptyFileWithRetry() throws {
//        let sut = makeSUT(permissionResponses: [true, true]).sut
//        let file = MockFileWithRetry(path: "/test/path.md", initialContent: "", retryContent: testContent)
//        let result = try sut.validateAndConfirmNoteFile(file)
//        
//        #expect(result.content == file.path)
//        #expect(result.isFromFile == true)
//    }
//    
//    @Test("Throws error when file remains empty after retry")
//    func throwsErrorForPersistentlyEmptyFile() throws {
//        let sut = makeSUT(permissionResponses: [true, true]).sut
//        let file = MockFile(path: "/test/path.md", content: "")
//        
//        #expect(throws: ReleaseNotesError.self) {
//            try sut.validateAndConfirmNoteFile(file)
//        }
//    }
//    
//    @Test("Handles user cancellation during initial confirmation")
//    func handlesUserCancellationDuringInitialConfirmation() throws {
//        let sut = makeSUT(shouldThrowPickerError: true).sut
//        let file = MockFile(path: "/test/path.md", content: testContent)
//        
//        #expect(throws: (any Error).self) {
//            try sut.validateAndConfirmNoteFile(file)
//        }
//    }
//    
//    @Test("Handles user cancellation during retry confirmation")
//    func handlesUserCancellationDuringRetryConfirmation() throws {
//        let sut = makeSUT(permissionResponses: [true], shouldThrowPickerError: true).sut
//        let file = MockFile(path: "/test/path.md", content: "")
//        
//        #expect(throws: (any Error).self) {
//            try sut.validateAndConfirmNoteFile(file)
//        }
//    }
//}
//
//
//// MARK: - SUT
//private extension ReleaseNotesFileUtilityTests {
//    func makeSUT(
//        fileContent: String = "",
//        permissionResponses: [Bool] = [],
//        shouldThrowPickerError: Bool = false
//    ) -> (sut: ReleaseNotesFileUtility, fileSystem: MockFileSystemProvider) {
//        let picker = MockSwiftPicker(
//            inputResult: .init(type: .ordered([])),
//            permissionResult: .init(type: .ordered(permissionResponses))
//        )
//
//        let fileSystem = MockFileSystemProvider(fileContent: fileContent)
//        let dateProvider = MockDateProvider(date: testDate)
//        let sut = ReleaseNotesFileUtility(
//            picker: picker,
//            fileSystem: fileSystem,
//            dateProvider: dateProvider
//        )
//
//        return (sut, fileSystem)
//    }
//}
//
//
//// MARK: - Test Helpers
//private class MockFileWithRetry: FileProtocol {
//    let path: String
//    private let initialContent: String
//    private let retryContent: String
//    private var readCount = 0
//    
//    init(path: String, initialContent: String, retryContent: String) {
//        self.path = path
//        self.initialContent = initialContent
//        self.retryContent = retryContent
//    }
//    
//    func readAsString() throws -> String {
//        defer { readCount += 1 }
//        return readCount == 0 ? initialContent : retryContent
//    }
//}

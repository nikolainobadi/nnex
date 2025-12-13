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
//    private let version = "1.2.3"
//    private let projectName = "TestProject"
//    private let testDate = Date(timeIntervalSince1970: 1691683200) // 2023-08-10
//    private let testContent = "Test release notes content"
//}
//
//
//// MARK: - createAndOpenNewNoteFile Tests
//extension ReleaseNotesFileUtilityTests {
//    @Test("Creates file with correct timestamp format")
//    func createsFileWithTimestamp() throws {
//        let (sut, desktop) = makeSUT()
//        let expectedFileName = "\(projectName)-releaseNotes-8-10-23.md"
//        _ = try sut.createAndOpenNewNoteFile(projectName: projectName)
//        
//        #expect(desktop.containedFiles.contains(expectedFileName))
//    }
//    
//    @Test("Returns file with correct path")
//    func returnsFileWithCorrectPath() throws {
//        let (sut, desktop) = makeSUT()
//        let filePath = try sut.createAndOpenNewNoteFile(projectName: projectName)
//        
//        #expect(filePath.contains(desktop.path))
//    }
//}
//
//
//// MARK: - createVersionedNoteFile Tests
//extension ReleaseNotesFileUtilityTests {
//    @Test("Creates versioned file with correct name")
//    func createsVersionedFile() throws {
//        let (sut, desktop) = makeSUT()
//        let expectedFileName = "\(projectName)-releaseNotes-v\(version).md"
//        _ = try sut.createVersionedNoteFile(projectName: projectName, version: version)
//        
//        #expect(desktop.containedFiles.contains(expectedFileName))
//    }
//    
//    @Test("Returns versioned file with correct path")
//    func returnsVersionedFileWithCorrectPath() throws {
//        let (sut, desktop) = makeSUT()
//        let filePath = try sut.createVersionedNoteFile(projectName: projectName, version: version)
//        
//        #expect(filePath.contains(desktop.path))
//    }
//}
//
//
//// MARK: - validateAndCon/firmNoteFile Tests
//extension ReleaseNotesFileUtilityTests {
//    @Test("Returns file path when file has content")
//    func returnsFilePathWithContent() throws {
//        let fileName = "path.md"
//        let directoryPath = "/test"
//        let filePath = "\(directoryPath)/\(fileName)"
//        let sut = makeSUT(permissionResponses: [true], file: (filePath, testContent)).sut
//        let result = try sut.validateAndConfirmNoteFile(filePath)
//
//        #expect(result.content == filePath)
//        #expect(result.isFromFile == true)
//    }
//    
//    @Test("Handles empty file with successful retry")
//    func handlesEmptyFileWithRetry() throws {
////        let sut = makeSUT(permissionResponses: [true, true]).sut
////        let file = MockFileWithRetry(path: "/test/path.md", initialContent: "", retryContent: testContent)
////        let result = try sut.validateAndConfirmNoteFile(file)
////
////        #expect(result.content == file.path)
////        #expect(result.isFromFile == true)
//    }
//    
//    @Test("Throws error when file remains empty after retry")
//    func throwsErrorForPersistentlyEmptyFile() throws {
////        let sut = makeSUT(permissionResponses: [true, true]).sut
////        let file = MockFile(path: "/test/path.md", content: "")
////
////        #expect(throws: ReleaseNotesError.self) {
////            try sut.validateAndConfirmNoteFile(file)
////        }
//    }
//    
//    @Test("Handles user cancellation during initial confirmation")
//    func handlesUserCancellationDuringInitialConfirmation() throws {
////        let sut = makeSUT(shouldThrowPickerError: true).sut
////        let file = MockFile(path: "/test/path.md", content: testContent)
////
////        #expect(throws: (any Error).self) {
////            try sut.validateAndConfirmNoteFile(file)
////        }
//    }
//    
//    @Test("Handles user cancellation during retry confirmation")
//    func handlesUserCancellationDuringRetryConfirmation() throws {
////        let sut = makeSUT(permissionResponses: [true], shouldThrowPickerError: true).sut
////        let file = MockFile(path: "/test/path.md", content: "")
////
////        #expect(throws: (any Error).self) {
////            try sut.validateAndConfirmNoteFile(file)
////        }
//    }
//}
//
//
//// MARK: - SUT
//private extension ReleaseNotesFileUtilityTests {
//    func makeSUT(permissionResponses: [Bool] = [], file: (path: String, contents: String)? = nil, date: Date? = nil) -> (sut: ReleaseNotesFileUtility, desktop: MockDirectory) {
//        let desktop = MockDirectory(path: "Desktop")
//        let picker = MockSwiftPicker(inputResult: .init(type: .ordered([])), permissionResult: .init(type: .ordered(permissionResponses)))
//
//        var directoryMap: [String: MockDirectory]? = nil
//        if let file {
//            let directoryPath = (file.path as NSString).deletingLastPathComponent
//            let fileName = (file.path as NSString).lastPathComponent
//            let directory = MockDirectory(path: directoryPath, containedFiles: [fileName])
//            directory.fileContents[fileName] = file.contents
//            directoryMap = [directoryPath: directory]
//        }
//
//        let fileSystem = MockFileSystem(directoryMap: directoryMap, desktop: desktop)
//        let dateProvider = MockDateProvider(date: date ?? testDate)
//        let sut = ReleaseNotesFileUtility(picker: picker, fileSystem: fileSystem, dateProvider: dateProvider)
//
//        return (sut, desktop)
//    }
//}

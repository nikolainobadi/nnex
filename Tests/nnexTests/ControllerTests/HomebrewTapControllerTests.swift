//
//  HomebrewTapControllerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import NnexKit
import Testing
import Foundation
import NnShellTesting
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex

final class HomebrewTapControllerTests {
    @Test("Starting values empty")
    func emptyStartingValues() {
        let (_, service) = makeSUT()
        
        #expect(service.savedPath == nil)
        #expect(service.savedTapData == nil)
    }
    
    @Test("Uses provided arguments when creating a tap")
    func createNewTapWithProvidedArguments() throws {
        let parent = MockDirectory(path: "/taps")
        let fileSystem = MockFileSystem(directoryToLoad: parent)
        let (sut, service) = makeSUT(directoryToLoad: parent, fileSystem: fileSystem)
        
        try sut.createNewTap(name: "myTap", details: "tap details", parentPath: parent.path, isPrivate: true)
        
        let tapData = try #require(service.savedTapData)
        
        #expect(tapData.name == "myTap")
        #expect(tapData.details == "tap details")
        #expect(tapData.parent.path == parent.path)
        #expect(tapData.isPrivate == true)
        #expect(service.savedPath == nil)
    }
    
    @Test("Prompts for missing name and details")
    func createNewTapPromptsForInputs() throws {
        let parent = MockDirectory(path: "/taps")
        let fileSystem = MockFileSystem(directoryToLoad: parent)
        let (sut, service) = makeSUT(inputResults: ["tapName", "tapDetails"], directoryToLoad: parent, fileSystem: fileSystem)
        
        try sut.createNewTap(name: nil, details: nil, parentPath: parent.path, isPrivate: false)
        
        let tapData = try #require(service.savedTapData)
        
        #expect(tapData.name == "tapName")
        #expect(tapData.details == "tapDetails")
        #expect(tapData.parent.path == parent.path)
        #expect(tapData.isPrivate == false)
    }
    
    @Test("Throws when tap name input is empty")
    func createNewTapEmptyNameThrows() {
        let parent = MockDirectory(path: "/taps")
        let fileSystem = MockFileSystem(directoryToLoad: parent)
        let (sut, service) = makeSUT(inputResults: [""], directoryToLoad: parent, fileSystem: fileSystem)
        
        #expect(throws: (any Error).self) {
            try sut.createNewTap(name: nil, details: "tap details", parentPath: parent.path, isPrivate: false)
        }
        
        #expect(service.savedTapData == nil)
    }
    
    @Test("Saves custom parent path when selected")
    func createNewTapWithCustomParentPath() throws {
        let browsedDirectory = MockDirectory(path: "/custom/taps")
        let (sut, service) = makeSUT(browsedDirectory: browsedDirectory)
        
        try sut.createNewTap(name: "tap", details: "details", parentPath: nil, isPrivate: false)
        
        let tapData = try #require(service.savedTapData)
        
        #expect(service.savedPath == browsedDirectory.path)
        #expect(tapData.parent.path == browsedDirectory.path)
    }
    
    @Test("Uses default tap list folder when selected")
    func createNewTapWithDefaultParentPath() throws {
        let expectedPath = "/Users/Home/NnexHomebrewTaps"
        let (sut, service) = makeSUT(selectionIndex: 1)
        
        try sut.createNewTap(name: "tap", details: "details", parentPath: nil, isPrivate: false)
        
        let tapData = try #require(service.savedTapData)
        
        #expect(service.savedPath == expectedPath)
        #expect(tapData.parent.path == expectedPath)
    }
    
    @Test("Propagates errors from service")
    func createNewTapServiceError() {
        let parent = MockDirectory(path: "/taps")
        let fileSystem = MockFileSystem(directoryToLoad: parent)
        let (sut, service) = makeSUT(directoryToLoad: parent, fileSystem: fileSystem, throwError: true)
        
        #expect(throws: (any Error).self) {
            try sut.createNewTap(name: "tap", details: "details", parentPath: parent.path, isPrivate: false)
        }
        
        #expect(service.savedTapData == nil)
    }
    
    @Test("Imports tap using provided path")
    func importTapWithPath() throws {
        let tapFolder = MockDirectory(path: "/taps/homebrew-myTap")
        let fileSystem = MockFileSystem(directoryToLoad: tapFolder)
        let (sut, service) = makeSUT(directoryToLoad: tapFolder, fileSystem: fileSystem)
        
        try sut.importTap(path: tapFolder.path)
        
        let imported = try #require(service.importedFolder)
        
        #expect(imported.path == tapFolder.path)
    }
    
    @Test("Imports tap after browsing for directory")
    func importTapWithBrowse() throws {
        let browsedDirectory = MockDirectory(path: "/taps/homebrew-myTap")
        let (sut, service) = makeSUT(browsedDirectory: browsedDirectory)
        
        try sut.importTap(path: nil)
        
        let imported = try #require(service.importedFolder)
        
        #expect(imported.path == browsedDirectory.path)
    }
}


// MARK: - SUT
private extension HomebrewTapControllerTests {
    func makeSUT(inputResults: [String] = [], directoryToLoad: MockDirectory? = nil, browsedDirectory: MockDirectory? = nil, selectionIndex: Int = 0, fileSystem: MockFileSystem? = nil, throwError: Bool = false) -> (sut: HomebrewTapController, service: MockService) {
        let picker = MockSwiftPicker(inputResult: .init(type: .ordered(inputResults)), selectionResult: .init(defaultSingle: .index(selectionIndex)))
        let fileSystem = fileSystem ?? MockFileSystem(directoryToLoad: directoryToLoad)
        let folderBrowser = MockDirectoryBrowser(filePathToReturn: nil, directoryToReturn: browsedDirectory)
        let service = MockService(throwError: throwError)
        let sut = HomebrewTapController(picker: picker, fileSystem: fileSystem, service: service, folderBrowser: folderBrowser)
        
        return (sut, service)
    }
}


// MARK: - Mocks
private extension HomebrewTapControllerTests {
    final class MockService: HomebrewTapService {
        private let throwError: Bool
        
        private(set) var savedPath: String?
        private(set) var importedFolder: (any Directory)?
        private(set) var savedTapData: (name: String, details: String, parent: any Directory, isPrivate: Bool)?
        
        init(throwError: Bool) {
            self.throwError = throwError
        }
        
        func saveTapListFolderPath(path: String) {
            savedPath = path
        }
        
        func createNewTap(named name: String, details: String, in parentFolder: any Directory, isPrivate: Bool) throws {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            savedTapData = (name, details, parentFolder, isPrivate)
        }
        
        func importTap(from folder: any Directory) throws -> HomebrewTapImportResult {
            if throwError { throw NSError(domain: "Test", code: 0) }
            
            importedFolder = folder
            
            return .init(tap: .init(name: folder.name, localPath: folder.path, remotePath: "", formulas: []), warnings: [])
        }
    }
}

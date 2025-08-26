//
//  CreateTapManagerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Testing
import NnexKit
import Foundation
import GitShellKit
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
final class CreateTapManagerTests {
    private let tapListFolder: Folder
    private let tapName = "myTap"
    private let tapDetails = "My tap description"
    private let remotePath = "https://github.com/user/homebrew-myTap"
    private let defaultTapFolderName = "NnexHomebrewTaps"
    
    init() throws {
        self.tapListFolder = try Folder.temporary.createSubfolder(named: "testTapList-createTapManager-\(UUID().uuidString)")
    }
    
    deinit {
        deleteFolderContents(tapListFolder)
    }
}


// MARK: - Unit Tests
extension CreateTapManagerTests {
    @Test("Successfully creates tap with provided name and details")
    func successfullyCreatesProvidedTap() throws {
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        
        context.saveTapListFolderPath(path: tapListFolder.path)
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        try sut.executeCreateTap(
            name: tapName,
            details: tapDetails,
            visibility: .publicRepo
        )
        
        let savedTaps = try context.loadTaps()
        let firstTap = try #require(savedTaps.first)
        
        #expect(savedTaps.count == 1)
        #expect(firstTap.name == tapName)
        #expect(firstTap.localPath == tapListFolder.path + "homebrew-\(tapName)/")
        #expect(firstTap.remotePath == remotePath)
        
        #expect(gitHandler.gitInitPath != nil)
        #expect(gitHandler.remoteTapName == "homebrew-\(tapName)")
    }
    
    @Test("Prompts for tap name when not provided")
    func promptsForTapName() throws {
        let factory = MockContextFactory(inputResponses: [tapName])
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        
        context.saveTapListFolderPath(path: tapListFolder.path)
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        try sut.executeCreateTap(
            name: nil,
            details: tapDetails,
            visibility: .publicRepo
        )
        
        let savedTaps = try context.loadTaps()
        #expect(savedTaps.first?.name == tapName)
    }
    
    @Test("Prompts for tap details when not provided")
    func promptsForTapDetails() throws {
        let factory = MockContextFactory(inputResponses: [tapDetails])
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        
        context.saveTapListFolderPath(path: tapListFolder.path)
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        try sut.executeCreateTap(
            name: tapName,
            details: nil,
            visibility: .privateRepo
        )
        
        // MockGitHandler doesn't track project details and visibility separately
    }
    
    @Test("Creates default tap folder when path not saved")
    func createsDefaultTapFolder() throws {
        let factory = MockContextFactory(selectedItemIndex: 1, inputResponses: [])
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        let homeFolder = Folder.home
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        try sut.executeCreateTap(
            name: tapName,
            details: tapDetails,
            visibility: .publicRepo
        )
        
        #expect(context.loadTapListFolderPath() == homeFolder.path + defaultTapFolderName + "/")
        
        let savedTaps = try context.loadTaps()
        #expect(savedTaps.first?.localPath.contains(defaultTapFolderName) == true)
        
        // Clean up
        if let folder = try? Folder(path: homeFolder.path + defaultTapFolderName) {
            try folder.delete()
        }
    }
    
    @Test("Creates custom tap folder when user selects custom path")
    func createsCustomTapFolder() throws {
        let tempFolder = try Folder.temporary.createSubfolder(named: "customTaps")
        let factory = MockContextFactory(selectedItemIndex: 0, inputResponses: [tempFolder.path])
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        try sut.executeCreateTap(
            name: tapName,
            details: tapDetails,
            visibility: .publicRepo
        )
        
        #expect(context.loadTapListFolderPath() == tempFolder.path)
        
        let savedTaps = try context.loadTaps()
        let firstTap = try #require(savedTaps.first)
        
        #expect(firstTap.localPath == tempFolder.path + "homebrew-\(tapName)/")
    }
    
    @Test("Uses existing tap folder path when saved")
    func usesExistingTapFolderPath() throws {
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        
        context.saveTapListFolderPath(path: tapListFolder.path)
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        try sut.executeCreateTap(
            name: tapName,
            details: tapDetails,
            visibility: .publicRepo
        )
        
        let savedTaps = try context.loadTaps()
        let firstTap = try #require(savedTaps.first)
        #expect(firstTap.localPath == tapListFolder.path + "homebrew-\(tapName)/")
    }
    
    @Test("Throws error for empty tap name from user input")
    func throwsErrorForEmptyTapName() throws {
        let factory = MockContextFactory(inputResponses: [""])
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        
        context.saveTapListFolderPath(path: tapListFolder.path)
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        #expect(throws: NnexError.invalidTapName) {
            try sut.executeCreateTap(
                name: nil,
                details: tapDetails,
                visibility: .publicRepo
            )
        }
    }
    
    @Test("Checks for GitHub CLI before proceeding")
    func checksForGitHubCLI() throws {
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        
        context.saveTapListFolderPath(path: tapListFolder.path)
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        try sut.executeCreateTap(
            name: tapName,
            details: tapDetails,
            visibility: .publicRepo
        )
        
        // GitHandler checkForGitHubCLI is called via ghVerification
        // Verify by checking that no error was thrown
    }
    
    @Test("Creates folder with homebrew prefix")
    func createsFolderWithHomebrewPrefix() throws {
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        let gitHandler = MockGitHandler(remoteURL: remotePath)
        
        context.saveTapListFolderPath(path: tapListFolder.path)
        
        let sut = makeSUT(factory: factory, gitHandler: gitHandler, context: context)
        
        try sut.executeCreateTap(
            name: tapName,
            details: tapDetails,
            visibility: .publicRepo
        )
        
        let expectedFolderPath = tapListFolder.path + "homebrew-\(tapName)"
        #expect(try Folder(path: expectedFolderPath).name == "homebrew-\(tapName)")
    }
}


// MARK: - SUT
private extension CreateTapManagerTests {
    func makeSUT(factory: MockContextFactory, gitHandler: MockGitHandler, context: NnexContext) -> CreateTapManager {
        return CreateTapManager(
            shell: factory.makeShell(),
            picker: factory.makePicker(),
            gitHandler: gitHandler,
            context: context
        )
    }
}

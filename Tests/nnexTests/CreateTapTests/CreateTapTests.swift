//
//  CreateTapTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import Testing
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
final class CreateTapTests {
    private let tapListFolder: Folder
    
    init() throws {
        self.tapListFolder = try Folder.temporary.createSubfolder(named: "tapListFolder")
    }
    
    deinit {
        deleteFolderContents(tapListFolder)
    }
}


// MARK: - Unit Tests
extension CreateTapTests {
    @Test("ensures no folders exist in temporary folder")
    func startingValuesEmpty() throws {
        let gitHandler = MockGitHandler()
        let factory = MockContextFactory(tapListFolderPath: tapListFolder.path, gitHandler: gitHandler)
        let context = try factory.makeContext()
        let tapList = try context.loadTaps()
        let subfolders = tapListFolder.subfolders.map({ $0 })
        
        #expect(tapList.isEmpty)
        #expect(subfolders.isEmpty)
        #expect(gitHandler.gitInitPath == nil)
        #expect(gitHandler.remoteTapName == nil)
        #expect(gitHandler.remoteTapPath == nil)
    }
    
    @Test("Cannot create tap if 'gh' is not installed")
    func createTapFailsWithoutGHCLI() throws {
        let gitHandler = MockGitHandler(ghIsInstalled: false)
        let factory = MockContextFactory(tapListFolderPath: tapListFolder.path, gitHandler: gitHandler)

        do {
            try runCommand(factory)
            Issue.record("Expected an error to be thrown")
        } catch { }
    }
    
    @Test("Creates new tap folder with 'homebrew-' prefix when name from arg does not include the prefix")
    func createsTapFolder() throws {
        let name = "myNewTap"
        let tapName = name.homebrewTapName
        let remoteURL = "remoteURL"
        let gitHandler = MockGitHandler(remoteURL: remoteURL)
        let factory = MockContextFactory(tapListFolderPath: tapListFolder.path, gitHandler: gitHandler)
        
        try runCommand(factory, name: name)
        
        let updatedTapListFolder = try Folder(path: tapListFolder.path)
        let tapFolder = try #require(try updatedTapListFolder.subfolder(named: tapName))
        
        #expect(tapFolder.name == tapName)
    }
    
    @Test("Creates new tap folder with 'homebrew-' prefix when name from input does not include the prefix")
    func createsTapFolderWithNameInput() throws {
        let name = "myNewTap"
        let tapName = name.homebrewTapName
        let remoteURL = "remoteURL"
        let gitHandler = MockGitHandler(remoteURL: remoteURL)
        let factory = MockContextFactory(tapListFolderPath: tapListFolder.path, inputResponses: [name], gitHandler: gitHandler)
        
        try runCommand(factory)
        
        let updatedTapListFolder = try Folder(path: tapListFolder.path)
        let tapFolder = try #require(try updatedTapListFolder.subfolder(named: tapName))
        
        #expect(tapFolder.name == tapName)
    }
    
    @Test("Throws error when name from input is empty")
    func createsTapInvalidNameError() throws {
        let factory = MockContextFactory(tapListFolderPath: tapListFolder.path, inputResponses: [""])

        do {
            try runCommand(factory)
            Issue.record("Expected an error to be thrown")
        } catch { }
    }
    
    // TODO: - need to verify other Tap properties
    @Test("Saves the newly created tap in SwiftData database")
    func savesCreatedTap() throws {
        let name = "myNewTap"
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        
        try runCommand(factory, name: name)
        
        #expect(try context.loadTaps().first?.name == name)
    }
    
    @Test("New repository is initialized for new Homebrew Tap folder")
    func newGitInitForTap() throws {
        let name = "myNewTap"
        let tapName = name.homebrewTapName
        let remoteURL = "remoteURL"
        let gitHandler = MockGitHandler(remoteURL: remoteURL)
        let factory = MockContextFactory(tapListFolderPath: tapListFolder.path, gitHandler: gitHandler)
        
        try runCommand(factory, name: name)
        
        let tapFolder = try #require(try Folder(path: tapListFolder.path).subfolder(named: tapName))
        
        #expect(gitHandler.gitInitPath == tapFolder.path)
        #expect(gitHandler.remoteTapName == tapName)
        #expect(gitHandler.remoteTapPath == tapFolder.path)
    }
}


// MARK: - Run Command
private extension CreateTapTests {
    func runCommand(_ testFactory: MockContextFactory, name: String? = nil) throws {
        var args = ["brew", "create-tap"]
        
        if let name {
            args = args + ["-n", name]
        }
        
        try Nnex.testRun(contextFactory: testFactory, args: args)
    }
}

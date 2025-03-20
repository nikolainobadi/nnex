//
//  CreateTapTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Testing
@testable import nnex

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
struct CreateTapTests {
    @Test("ensures no folders exist in temporary folder")
    func startingValuesEmpty() throws {
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        let loader = factory.makeFolderLoader()
        let tapList = try context.loadTaps()
        let subfolders = try loader.loadTapListFolder().subfolders.map({ $0 })
        
        #expect(tapList.isEmpty)
        #expect(subfolders.isEmpty)
    }
    
    @Test("Creates new tap folder with 'homebrew-' prefix when its missing from input name")
    func createTapFolder() throws {
        let name = "myNewTap"
        let factory = MockContextFactory(inputResponses: [name])
        let loader = factory.makeFolderLoader()
        
        try runCommand(factory)
        
        let temporaryFolder = try loader.loadTapListFolder()
        let newTapFolder = try? temporaryFolder.subfolder(named: name.homebrewTapName)
        
        #expect(newTapFolder != nil)
    }
    
    // TODO: - need to verify other Tap properties
    @Test("Saves the newly created tap in SwiftData database")
    func savesCreatedTap() throws {
        let name = "myNewTap"
        let factory = MockContextFactory(inputResponses: [name])
        let context = try factory.makeContext()
        
        try runCommand(factory)
        
        #expect(try context.loadTaps().first?.name == name)
    }
}


// MARK: - Run Command
private extension CreateTapTests {
    func runCommand(_ testFactory: MockContextFactory) throws {
        try Nnex.testRun(contextFactory: testFactory, args: ["brew", "create-tap"])
    }
}

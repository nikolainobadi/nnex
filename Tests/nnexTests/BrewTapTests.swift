//
//  BrewTapTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Testing
@testable import nnex

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
struct BrewTapTests {
    @Test("ensures no folders exist in temporary folder")
    func startingValuesEmpty() throws {
        let testFactory = TestContextFactory()
        let context = try testFactory.makeContext()
        let loader = testFactory.makeFolderLoader()
        
        let tapList = try context.loadTaps()
        let subfolders = try loader.loadTapListFolder().subfolders.map({ $0 })
        
        #expect(tapList.isEmpty)
        #expect(subfolders.isEmpty)
    }
    
    @Test("Creates new tap folder with 'homebrew-' prefix when its missing from input name")
    func createTapFolder() throws {
        let inputName = "myNewTap"
        let fullTapName = addHomebrewPrefix(to: inputName)
        let handler = BrewTapInputHandler(newTapName: inputName)
        let testFactory = TestContextFactory(inputProvider: handler.getInput(_:))
        let loader = testFactory.makeFolderLoader()
        
        try runCommand(testFactory)
        
        let temporaryFolder = try loader.loadTapListFolder()
        let newTapFolder = try? temporaryFolder.subfolder(named: fullTapName)
        
        #expect(newTapFolder != nil)
    }
    
    // TODO: - need to verify other Tap properties
    @Test("Saves the newly created tap in SwiftData database")
    func savesCreatedTap() throws {
        let inputName = "myNewTap"
        let handler = BrewTapInputHandler(newTapName: inputName)
        let testFactory = TestContextFactory(inputProvider: handler.getInput(_:))
        let context = try testFactory.makeContext()
        
        try runCommand(testFactory)
        
        #expect(try context.loadTaps().first?.name == addHomebrewPrefix(to: inputName))
    }
}


// MARK: - Run Command
private extension BrewTapTests {
    func addHomebrewPrefix(to name: String) -> String {
        return .homebrewPrefix + name
    }
    
    func runCommand(_ testFactory: TestContextFactory) throws {
        try Nnex.testRun(contextFactory: testFactory, args: ["brew", "tap"])
    }
}


// MARK: - Input Helpers
struct BrewTapInputHandler {
    private let newTapName: String
    
    init(newTapName: String = "") {
        self.newTapName = newTapName
    }
    
    func getInput(_ type: InputType) -> String {
        switch type {
        case .newTap:
            return newTapName
        }
    }
}

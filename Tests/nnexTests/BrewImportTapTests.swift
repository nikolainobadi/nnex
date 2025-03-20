//
//  BrewImportTapTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Testing
@testable import nnex

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
struct BrewImportTapTests {
    @Test("ensures no taps exist in database")
    func startingValuesEmpty() throws {
        let testFactory = TestContextFactory()
        let context = try testFactory.makeContext()
        
        #expect(try context.loadTaps().isEmpty)
    }
    
    @Test("Imports tap from existing folder")
    func first() throws {
        // TODO: - need to create folder
        let tapName = "nntools"
        let path = "/Users/nelix/Desktop/homebrew-\(tapName)"
        let testFactory = TestContextFactory()
        let context = try testFactory.makeContext()
        
        try runCommand(testFactory, path: path)
        
        let tapList = try context.loadTaps()
        let newTap = tapList.first!
        
        #expect(newTap.name == tapName)
        #expect(newTap.formulas.count == 1)
    }
}


// MARK: - Run Command
private extension BrewImportTapTests {
    func runCommand(_ testFactory: TestContextFactory, path: String = "") throws {
        if path.isEmpty {
            try Nnex.testRun(contextFactory: testFactory, args: ["brew", "import-tap"])
        } else {
            try Nnex.testRun(contextFactory: testFactory, args: ["brew", "import-tap", "-p", path])
        }
    }
}

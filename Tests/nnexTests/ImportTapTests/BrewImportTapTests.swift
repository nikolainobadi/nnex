//
//  BrewImportTapTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import Testing
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
final class BrewImportTapTests {
    private let tapName = "testTap"
    private let tapFolder: Folder
    
    init() throws {
        self.tapFolder = try Folder.temporary.createSubfolder(named: tapName.homebrewTapName)
    }
    
    deinit {
        deleteFolderContents(tapFolder)
    }
}


// MARK: - Unit Tests
extension BrewImportTapTests {
    @Test("ensures no taps exist in database")
    func startingValuesEmpty() throws {
        let testFactory = MockContextFactory()
        let context = try testFactory.makeContext()
        
        #expect(try context.loadTaps().isEmpty)
    }
    
    @Test("Imports empty tap from existing folder when path is passed as arg")
    func importsEmptyTap() throws {
        let testFactory = MockContextFactory()
        let context = try testFactory.makeContext()
        
        try runCommand(testFactory, path: tapFolder.path)
        
        let newTap = try #require(try context.loadTaps().first)
        
        #expect(newTap.name == tapName)
        #expect(newTap.formulas.isEmpty)
    }
    
    @Test("Imports empty tap from existing folder from selection", .disabled()) // TODO: - 
    func importsEmptyTapFromSelection() throws {
        MockSwiftPicker.folderToReturn = tapFolder
        
        let testFactory = MockContextFactory()
        let context = try testFactory.makeContext()
        
        try runCommand(testFactory)
        
        let newTap = try #require(try context.loadTaps().first)
        
        #expect(newTap.name == tapName)
        #expect(newTap.formulas.isEmpty)
    }
    
    
    
    @Test("Imports tap from existing folder and decodes existing formula when path is passed as arg")
    func importTapWithFormula() throws {
        let name = "testFormula"
        let details = "formula details"
        let homepage = "homepage"
        let license = "MIT"
        let testFactory = MockContextFactory()
        let context = try testFactory.makeContext()
        let formulaContent = FormulaContentGenerator.makeFormulaFileContent(name: name, details: details, homepage: homepage, license: license, version: "1.0.0", assetURL: "assetURL", sha256: "sha256")

        let formulaFolder = try tapFolder.createSubfolder(named: "Formula")
        let formulaFile = try formulaFolder.createFile(named: "\(name).rb")
        try formulaFile.write(formulaContent)
        
        try runCommand(testFactory, path: tapFolder.path)
        
        let tapList = try context.loadTaps()
        let newTap = try #require(tapList.first)
        let formulaList = try context.loadFormulas()
        let newFormula = try #require(formulaList.first)
        
        #expect(newTap.name == tapName)
        #expect(newTap.formulas.count == 1)
        #expect(newFormula.name == name.capitalized)
        #expect(newFormula.details == details)
        #expect(newFormula.homepage == homepage)
        #expect(newFormula.license == license)
    }

    @Test("Imports tap without Formula folder and shows warning when path is passed as arg")
    func importsTapWithoutFormulaFolder() throws {
        let testFactory = MockContextFactory()
        let context = try testFactory.makeContext()

        try runCommand(testFactory, path: tapFolder.path)

        let newTap = try #require(try context.loadTaps().first)

        #expect(newTap.name == tapName)
        #expect(newTap.formulas.isEmpty)
    }
}


// MARK: - Run Command
private extension BrewImportTapTests {
    func runCommand(_ testFactory: MockContextFactory, path: String? = nil) throws {
        var args = ["brew", "import-tap"]
        
        if let path {
            args = args + ["-p", path]
        }
        
        try Nnex.testRun(contextFactory: testFactory, args: args)
    }
}

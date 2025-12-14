//
//  RemoveFormulaTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

import NnexKit
import Testing
import Foundation
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor
final class RemoveFormulaTests {
    private let tapName = "testTap"
    private let tempFolder: Folder
    private let tapFolder: Folder

    init() throws {
        self.tempFolder = try Folder.temporary.createSubfolder(named: "RemoveFormulaTests_\(UUID().uuidString)")
        self.tapFolder = try tempFolder.createSubfolder(named: tapName.homebrewTapName)
    }

    deinit {
        deleteFolderContents(tempFolder)
        try? tempFolder.delete()
    }
}


// MARK: - Unit Tests
extension RemoveFormulaTests {
    @Test("ensures no formulas exist in database")
    func startingValuesEmpty() throws {
        let testFactory = MockContextFactory()
        let context = try testFactory.makeContext()

        #expect(try context.loadFormulas().isEmpty)
    }

    @Test("Removes formula from database")
    func removesFormulaFromDatabase() throws {
        let name = "testFormula"
        let testFactory = MockContextFactory(tapListFolderPath: tempFolder.path)

        try createTestTapAndFormula(factory: testFactory, formulaName: name)

        let context = try testFactory.makeContext()
        let formulasBeforeRemoval = try context.loadFormulas()
        #expect(formulasBeforeRemoval.count == 1)

        try runCommand(testFactory)

        let formulasAfterRemoval = try context.loadFormulas()
        #expect(formulasAfterRemoval.isEmpty)
    }

    @Test("Deletes formula file from Formula folder when user confirms")
    func deletesFormulaFileWhenUserConfirms() throws {
        let name = "testFormula"
        let testFactory = MockContextFactory(tapListFolderPath: tempFolder.path, permissionResponses: [true])

        try createTestTapAndFormula(factory: testFactory, formulaName: name, createFormulaFile: true)

        let formulaFolder = try tapFolder.subfolder(named: "Formula")
        #expect(formulaFolder.containsFile(named: "\(name).rb"))

        try runCommand(testFactory)

        let updatedFormulaFolder = try Folder(path: formulaFolder.path)
        #expect(!updatedFormulaFolder.containsFile(named: "\(name).rb"))

        let context = try testFactory.makeContext()
        #expect(try context.loadFormulas().isEmpty)
    }

    @Test("Keeps formula file in Formula folder when user declines deletion")
    func keepsFormulaFileWhenUserDeclines() throws {
        let name = "testFormula"
        let testFactory = MockContextFactory(tapListFolderPath: tempFolder.path, permissionResponses: [false])

        try createTestTapAndFormula(factory: testFactory, formulaName: name, createFormulaFile: true)

        let formulaFolder = try tapFolder.subfolder(named: "Formula")
        #expect(formulaFolder.containsFile(named: "\(name).rb"))

        try runCommand(testFactory)

        let updatedFormulaFolder = try Folder(path: formulaFolder.path)
        #expect(updatedFormulaFolder.containsFile(named: "\(name).rb"))

        let context = try testFactory.makeContext()
        #expect(try context.loadFormulas().isEmpty)
    }

    @Test("Handles missing Formula folder gracefully")
    func handlesMissingFormulaFolder() throws {
        let name = "testFormula"
        let testFactory = MockContextFactory(tapListFolderPath: tempFolder.path, permissionResponses: [true])

        try createTestTapAndFormula(factory: testFactory, formulaName: name, createFormulaFile: false)

        let context = try testFactory.makeContext()
        let formulasBeforeRemoval = try context.loadFormulas()
        #expect(formulasBeforeRemoval.count == 1)

        try runCommand(testFactory)

        let formulasAfterRemoval = try context.loadFormulas()
        #expect(formulasAfterRemoval.isEmpty)
    }
}


// MARK: - Helper Methods
private extension RemoveFormulaTests {
    func runCommand(_ testFactory: MockContextFactory) throws {
        let args = ["brew", "remove-formula"]
        try Nnex.testRun(contextFactory: testFactory, args: args)
    }

    func createTestTapAndFormula(factory: MockContextFactory, formulaName: String, createFormulaFile: Bool = false) throws {
        let context = try factory.makeContext()
        let tap = SwiftDataHomebrewTap(name: tapName, localPath: tapFolder.path, remotePath: "https://github.com/user/\(tapName)")
        let formula = SwiftDataHomebrewFormula(name: formulaName, details: "formula details", homepage: "https://github.com/user/\(formulaName)", license: "MIT", localProjectPath: "/path/to/project", uploadType: .binary, testCommand: nil, extraBuildArgs: [])

        try context.saveNewTap(tap, formulas: [formula])

        if createFormulaFile {
            let formulaFolder = try tapFolder.createSubfolderIfNeeded(withName: "Formula")
            let formulaContent = FormulaContentGenerator.makeFormulaFileContent(formulaName: formulaName, installName: formulaName, details: "formula details", homepage: "https://github.com/user/\(formulaName)", license: "MIT", version: "1.0.0", assetURL: "https://example.com/asset", sha256: "abc123")
            let formulaFile = try formulaFolder.createFile(named: "\(formulaName).rb")
            try formulaFile.write(formulaContent)
        }
    }
}

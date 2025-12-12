//
//  HomebrewFormulaControllerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/31/25.
//

import NnexKit
import Testing
import Foundation
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex

final class HomebrewFormulaControllerTests {
    @Test("Starting values empty")
    func startingValuesEmpty() {
        let (_, service) = makeSUT()
        
        #expect(service.deletedFormula == nil)
    }
    
    @Test("Deletes selected formula via service")
    func removeFormulaDeletesViaService() throws {
        let formula = makeFormula(name: "tool", tapPath: "")
        let (sut, service) = makeSUT(formulaeToLoad: [formula])
        
        try sut.removeFormula()
        
        let deleted = try #require(service.deletedFormula)
        #expect(deleted.name == formula.name)
    }
    
    @Test("Deletes formula file when confirmed")
    func removeFormulaDeletesFileWhenConfirmed() throws {
        let tapPath = "/taps/homebrew-tool"
        let formulaDirectory = MockDirectory(path: tapPath.appendingPathComponent("Formula"), containedFiles: ["tool.rb"])
        let tapDirectory = MockDirectory(path: tapPath, subdirectories: [formulaDirectory])
        let fileSystem = MockFileSystem(directoryMap: [tapPath: tapDirectory])
        let formula = makeFormula(name: "tool", tapPath: tapPath)
        let (sut, service) = makeSUT(formulaeToLoad: [formula], permissionResponses: [true], fileSystem: fileSystem)
        
        try sut.removeFormula()
        
        #expect(!formulaDirectory.containedFiles.contains("tool.rb"))
        #expect(service.deletedFormula?.name == "tool")
    }
    
    @Test("Keeps formula file when permission denied")
    func removeFormulaKeepsFileWhenPermissionDenied() throws {
        let tapPath = "/taps/homebrew-tool"
        let formulaDirectory = MockDirectory(path: tapPath.appendingPathComponent("Formula"), containedFiles: ["tool.rb"])
        let tapDirectory = MockDirectory(path: tapPath, subdirectories: [formulaDirectory])
        let fileSystem = MockFileSystem(directoryMap: [tapPath: tapDirectory])
        let formula = makeFormula(name: "tool", tapPath: tapPath)
        let (sut, service) = makeSUT(formulaeToLoad: [formula], permissionResponses: [false], fileSystem: fileSystem)
        
        try sut.removeFormula()
        
        #expect(formulaDirectory.containedFiles.contains("tool.rb"))
        #expect(service.deletedFormula?.name == "tool")
    }
    
    @Test("Skips file handling when tap path missing")
    func removeFormulaSkipsFileWhenPathMissing() throws {
        let formula = makeFormula(name: "tool", tapPath: "")
        let (sut, service) = makeSUT(formulaeToLoad: [formula], fileSystem: MockFileSystem())
        
        try sut.removeFormula()
        
        let deleted = try #require(service.deletedFormula)
        #expect(deleted.name == "tool")
    }
    
    @Test("Propagates service delete errors")
    func removeFormulaPropagatesServiceErrors() {
        let formula = makeFormula(name: "tool", tapPath: "")
        let (sut, service) = makeSUT(formulaeToLoad: [formula], throwErrorOnDelete: true)
        
        #expect(throws: (any Error).self) {
            try sut.removeFormula()
        }
        
        #expect(service.deletedFormula == nil)
    }
}


// MARK: - SUT
private extension HomebrewFormulaControllerTests {
    func makeSUT(
        formulaeToLoad: [HomebrewFormula] = [],
        permissionResponses: [Bool] = [],
        selectionIndex: Int = 0,
        fileSystem: MockFileSystem? = nil,
        throwErrorOnDelete: Bool = false
    ) -> (sut: HomebrewFormulaController, service: MockService) {
        let picker = MockSwiftPicker(
            inputResult: .init(type: .ordered([])),
            permissionResult: .init(type: .ordered(permissionResponses)),
            selectionResult: .init(defaultSingle: .index(selectionIndex))
        )
        let service = MockService(formulaeToLoad: formulaeToLoad, throwErrorOnDelete: throwErrorOnDelete)
        let fileSystem = fileSystem ?? MockFileSystem()
        let sut = HomebrewFormulaController(picker: picker, fileSystem: fileSystem, service: service)
        
        return (sut, service)
    }
    
    func makeFormula(name: String, tapPath: String) -> HomebrewFormula {
        .init(
            name: name,
            details: "details",
            homepage: "homepage",
            license: "license",
            localProjectPath: "",
            uploadType: .binary,
            testCommand: nil,
            extraBuildArgs: [],
            tapLocalPath: tapPath
        )
    }
}


// MARK: - Mocks
private extension HomebrewFormulaControllerTests {
    final class MockService: HomebrewFormulaService {
        private let formulaeToLoad: [HomebrewFormula]
        private let throwErrorOnDelete: Bool
        
        private(set) var deletedFormula: HomebrewFormula?
        
        init(formulaeToLoad: [HomebrewFormula], throwErrorOnDelete: Bool) {
            self.formulaeToLoad = formulaeToLoad
            self.throwErrorOnDelete = throwErrorOnDelete
        }
        
        func loadFormulas() throws -> [HomebrewFormula] {
            return formulaeToLoad
        }
        
        func deleteFormula(_ formula: HomebrewFormula) throws {
            if throwErrorOnDelete { throw NSError(domain: "Test", code: 0) }
            deletedFormula = formula
        }
    }
}

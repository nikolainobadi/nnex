////
////  PublishInfoLoaderTests.swift
////  nnex
////
////  Created by Nikolai Nobadi on 8/11/25.
////
//
//import NnexKit
//import Testing
//import Foundation
//import NnShellTesting
//import SwiftPickerTesting
//import NnexSharedTestHelpers
//@testable import nnex
//@preconcurrency import Files
//
//@MainActor
//final class PublishInfoLoaderTests: BasePublishTestSuite {
//    private let tapName = "testTap"
//    private let projectName = "testProject-publishInfoLoader"
//    
//    init() throws {
//        try super.init(tapName: tapName, projectName: projectName)
//    }
//}
//
//
//// MARK: - Tests
//extension PublishInfoLoaderTests {
//    @Test("Creates new formula when project has no existing formula")
//    func createsNewFormula() throws {
//        let store = MockHomebrewTapStore(taps: [
//            HomebrewTap(name: tapName, localPath: tapFolder.path, remotePath: "", formulas: [])
//        ])
//        
//        let sut = try makeSUT(
//            store: store,
//            inputResponses: ["Test formula description"],
//            permissionResponses: [true],
//            selectedItemIndices: [0, 2] // Index 0 for tap selection, index 2 for FormulaTestType.noTests
//        )
//        
//        try createPackageSwift()
//        
//        let (tap, formula) = try sut.loadPublishInfo()
//        let newFormulaData = try #require(store.newFormulaData)
//        
//        #expect(tap.name == tapName)
//        #expect(formula.name == projectName)
//        #expect(newFormulaData.tap.name.matches(tap.name))
//        #expect(newFormulaData.formula.name.matches(formula.name))
//    }
//    
//    @Test("Updates formula localProjectPath when it doesn't match current project folder")
//    func updatesFormulaProjectPath() throws {
//        // Create a formula with a different project path
//        let existingFormula = HomebrewFormula(
//            name: projectName,
//            details: "Test formula",
//            homepage: "https://github.com/test/test",
//            license: "MIT",
//            localProjectPath: "/old/path/to/project", // Different path
//            uploadType: .binary,
//            testCommand: nil,
//            extraBuildArgs: []
//        )
//        
//        let store = MockHomebrewTapStore(taps: [
//            HomebrewTap(name: tapName, localPath: tapFolder.path, remotePath: "", formulas: [existingFormula])
//        ])
//        
//        let sut = try makeSUT(store: store)
//        
//        // Create Package.swift file
//        try createPackageSwift()
//        
//        let (tap, formula) = try sut.loadPublishInfo()
//        
//        #expect(tap.name == tapName)
//        #expect(formula.name == projectName)
//        #expect(formula.localProjectPath == projectFolder.path) // Should be updated to current project path
//        #expect(store.formulaToUpdate?.localProjectPath == projectFolder.path)
//    }
//    
//    @Test("Preserves formula localProjectPath when it matches current project folder")
//    func preservesMatchingProjectPath() throws {
//        // Create a formula with the same project path
//        let existingFormula = HomebrewFormula(
//            name: projectName,
//            details: "Test formula",
//            homepage: "https://github.com/test/test",
//            license: "MIT",
//            localProjectPath: projectFolder.path, // Same path
//            uploadType: .binary,
//            testCommand: nil,
//            extraBuildArgs: []
//        )
//        
//        let store = MockHomebrewTapStore(taps: [
//            HomebrewTap(name: tapName, localPath: tapFolder.path, remotePath: "", formulas: [existingFormula])
//        ])
//        let sut = try makeSUT(store: store)
//        
//        // Create Package.swift file
//        try createPackageSwift()
//        
//        let (tap, formula) = try sut.loadPublishInfo()
//        
//        #expect(tap.name == tapName)
//        #expect(formula.name == projectName)
//        #expect(formula.localProjectPath == projectFolder.path) // Should remain the same
//        #expect(store.formulaToUpdate == nil)
//    }
//}
//
//
//// MARK: - SUT
//private extension PublishInfoLoaderTests {
//    func makeSUT(store: MockHomebrewTapStore, skipTests: Bool = false, inputResponses: [String] = [], permissionResponses: [Bool] = [], selectedItemIndices: [Int] = []) throws -> PublishInfoLoader {
//        let shell = MockShell()
//        let gitHandler = MockGitHandler()
//        let picker = MockSwiftPicker(
//            inputResult: .init(type: .ordered(inputResponses)),
//            permissionResult: .init(type: .ordered(permissionResponses)),
//            selectionResult: .init(singleType: .ordered(selectedItemIndices.map({ .index($0) })))
//        )
//        let folderAdapter = FilesDirectoryAdapter(folder: projectFolder)
//        let sut = PublishInfoLoader(
//            shell: shell,
//            picker: picker,
//            gitHandler: gitHandler,
//            store: store,
//            projectFolder: folderAdapter,
//            skipTests: skipTests
//        )
//        
//        return sut
//    }
//}

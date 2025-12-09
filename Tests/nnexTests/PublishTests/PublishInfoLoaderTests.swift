////
////  PublishInfoLoaderTests.swift
////  nnex
////
////  Created by Nikolai Nobadi on 8/11/25.
////
//
//import NnexKit
//import Testing
//import NnShellKit
//import Foundation
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
//        let factory = MockContextFactory()
//        let context = try factory.makeContext()
//        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
//        
//        try context.saveNewTap(existingTap)
//        
//        let sut = try makeSUT(
//            context: context,
//            inputResponses: ["Test formula description"],
//            permissionResponses: [true],
//            selectedItemIndices: [0, 2] // Index 0 for tap selection, index 2 for FormulaTestType.noTests
//        )
//        
//        try createPackageSwift()
//        
//        let (tap, formula) = try sut.loadPublishInfo()
//        
//        #expect(tap.name == tapName)
//        #expect(formula.name == projectName)
//    }
//    
//    @Test("Updates formula localProjectPath when it doesn't match current project folder")
//    func updatesFormulaProjectPath() throws {
//        let factory = MockContextFactory()
//        let context = try factory.makeContext()
//        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
//        
//        // Create a formula with a different project path
//        let existingFormula = SwiftDataFormula(
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
//        try context.saveNewTap(existingTap, formulas: [existingFormula])
//        
//        let sut = try makeSUT(context: context)
//        
//        // Create Package.swift file
//        try createPackageSwift()
//        
//        let (tap, formula) = try sut.loadPublishInfo()
//        
//        #expect(tap.name == tapName)
//        #expect(formula.name == projectName)
//        #expect(formula.localProjectPath == projectFolder.path) // Should be updated to current project path
//    }
//    
//    @Test("Preserves formula localProjectPath when it matches current project folder")
//    func preservesMatchingProjectPath() throws {
//        let factory = MockContextFactory()
//        let context = try factory.makeContext()
//        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
//        
//        let sut = try makeSUT(context: context)
//        
//        // Create Package.swift file
//        try createPackageSwift()
//        
//        // Create a formula with the same project path
//        let existingFormula = SwiftDataFormula(
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
//        try context.saveNewTap(existingTap, formulas: [existingFormula])
//        
//        let (tap, formula) = try sut.loadPublishInfo()
//        
//        #expect(tap.name == tapName)
//        #expect(formula.name == projectName)
//        #expect(formula.localProjectPath == projectFolder.path) // Should remain the same
//    }
//}
//
//
//// MARK: - SUT
//private extension PublishInfoLoaderTests {
//    func makeSUT(context: NnexContext, skipTests: Bool = false, inputResponses: [String] = [], permissionResponses: [Bool] = [], selectedItemIndices: [Int] = []) throws -> PublishInfoLoader {
//        let shell = MockShell()
//        let gitHandler = MockGitHandler()
//        let picker = MockSwiftPicker(
//            inputResult: .init(type: .ordered(inputResponses)),
//            permissionResult: .init(type: .ordered(permissionResponses)),
//            selectionResult: .init(singleType: .ordered(selectedItemIndices.map({ .index($0) })))
//        ) 
//        let sut = PublishInfoLoader(
//            shell: shell,
//            picker: picker,
//            projectFolder: projectFolder,
//            context: context,
//            gitHandler: gitHandler,
//            skipTests: skipTests
//        )
//        
//        return sut
//    }
//}

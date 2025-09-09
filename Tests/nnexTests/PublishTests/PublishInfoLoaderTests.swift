//
//  PublishInfoLoaderTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/11/25.
//

import NnexKit
import Testing
import NnShellKit
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor
final class PublishInfoLoaderTests {
    private let tapFolder: Folder
    private let projectFolder: Folder
    private let tapName = "testTap"
    private let projectName = "testProject-publishInfoLoader"
    
    init() throws {
        let tempFolder = Folder.temporary
        self.projectFolder = try tempFolder.createSubfolder(named: projectName)
        self.tapFolder = try tempFolder.createSubfolder(named: "homebrew-\(tapName)-publishInfoLoader")
    }
    
    deinit {
        deleteFolderContents(tapFolder)
        deleteFolderContents(projectFolder)
    }
}


// MARK: - Tests
extension PublishInfoLoaderTests {
    @Test("Creates new formula when project has no existing formula")
    func createsNewFormula() throws {
        // Create Package.swift file
        try createPackageSwift()
        
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        
        try context.saveNewTap(existingTap)
        
        let sut = makeSUT(
            context: context,
            inputResponses: ["Test formula description"],
            permissionResponses: [true],
            selectedItemIndices: [0, 2] // Index 0 for tap selection, index 2 for FormulaTestType.noTests
        )
        let (tap, formula) = try sut.loadPublishInfo()
        
        #expect(tap.name == tapName)
        #expect(formula.name == projectName)
    }
    
    @Test("Updates formula localProjectPath when it doesn't match current project folder")
    func updatesFormulaProjectPath() throws {
        // Create Package.swift file
        try createPackageSwift()
        
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        
        // Create a formula with a different project path
        let existingFormula = SwiftDataFormula(
            name: projectName,
            details: "Test formula",
            homepage: "https://github.com/test/test",
            license: "MIT",
            localProjectPath: "/old/path/to/project", // Different path
            uploadType: .binary,
            testCommand: nil,
            extraBuildArgs: []
        )
        
        try context.saveNewTap(existingTap, formulas: [existingFormula])
        
        let sut = makeSUT(context: context)
        let (tap, formula) = try sut.loadPublishInfo()
        
        #expect(tap.name == tapName)
        #expect(formula.name == projectName)
        #expect(formula.localProjectPath == projectFolder.path) // Should be updated to current project path
    }
    
    @Test("Preserves formula localProjectPath when it matches current project folder")
    func preservesMatchingProjectPath() throws {
        // Create Package.swift file
        try createPackageSwift()
        
        let factory = MockContextFactory()
        let context = try factory.makeContext()
        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        
        // Create a formula with the same project path
        let existingFormula = SwiftDataFormula(
            name: projectName,
            details: "Test formula",
            homepage: "https://github.com/test/test",
            license: "MIT",
            localProjectPath: projectFolder.path, // Same path
            uploadType: .binary,
            testCommand: nil,
            extraBuildArgs: []
        )
        
        try context.saveNewTap(existingTap, formulas: [existingFormula])
        
        let sut = makeSUT(context: context)
        let (tap, formula) = try sut.loadPublishInfo()
        
        #expect(tap.name == tapName)
        #expect(formula.name == projectName)
        #expect(formula.localProjectPath == projectFolder.path) // Should remain the same
    }
}


// MARK: - SUT
private extension PublishInfoLoaderTests {
    func makeSUT(context: NnexContext, skipTests: Bool = false, inputResponses: [String] = [], permissionResponses: [Bool] = [], selectedItemIndices: [Int] = []) -> PublishInfoLoader {
        let shell = MockShell()
        let picker = MockPicker(
            selectedItemIndices: selectedItemIndices,
            inputResponses: inputResponses,
            permissionResponses: permissionResponses
        )
        let gitHandler = MockGitHandler()
        
        return .init(
            shell: shell,
            picker: picker,
            projectFolder: projectFolder,
            context: context,
            gitHandler: gitHandler,
            skipTests: skipTests
        )
    }
    
    func createPackageSwift(name: String? = nil, targetName: String? = nil) throws {
        let packageContent = """
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "\(name ?? projectName)",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "\(name ?? projectName)", targets: ["\(targetName ?? projectName)"])
    ],
    targets: [
        .executableTarget(
            name: "\(targetName ?? projectName)",
            path: "Sources"
        )
    ]
)
"""
        try projectFolder.createFile(named: "Package.swift", contents: packageContent.data(using: .utf8)!)
    }
}

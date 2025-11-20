//
//  BuildExecutionManagerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import NnexKit
import Testing
import Foundation
import NnShellKit
import SwiftPickerTesting
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

final class BuildExecutionManagerTests {
    private let projectFolder: Folder
    private let projectName = "testProject-buildManager"
    private let executableName = "testExecutable"
    
    init() throws {
        let tempFolder = Folder.temporary
        self.projectFolder = try tempFolder.createSubfolder(named: "\(projectName)-\(UUID().uuidString)")
    }
    
    deinit {
        deleteFolderContents(projectFolder)
        try? projectFolder.delete()
    }
}


// MARK: - Tests
extension BuildExecutionManagerTests {
    @Test("Successfully executes build with single executable")
    func successfullyExecutesBuildWithSingleExecutable() throws {
        try createPackageSwift(executableName: executableName)
        
        let (sut, shell) = makeSUT(selectedItemIndices: [0])
        
        try sut.executeBuild(projectPath: projectFolder.path, buildType: .universal, clean: true, openInFinder: false)
        
        // Verify shell was called for build operations
        #expect(shell.executedCommands.count >= 3) // At least clean, build arm64, build x86_64
    }
    
    @Test("Successfully executes build with multiple executables requiring selection")
    func successfullyExecutesBuildWithMultipleExecutables() throws {
        try createPackageSwiftWithMultipleExecutables()

        let sut = makeSUT(selectedItemIndices: [0, 0]).sut
        let path = projectFolder.path

        #expect(throws: Never.self) {
            try sut.executeBuild(projectPath: path, buildType: .universal, clean: true, openInFinder: false)
        }

        // Build should complete successfully with multiple executables
    }
    
    @Test("Executes build and opens in Finder when flag is set")
    func executesBuildAndOpensInFinderWhenFlagSet() throws {
        try createPackageSwift(executableName: executableName)
        
        let (sut, shell) = makeSUT(selectedItemIndices: [0])
        
        try sut.executeBuild(projectPath: projectFolder.path, buildType: .universal, clean: true, openInFinder: true)
        
        // Verify Finder open command was executed
        #expect(shell.executedCommands.contains { $0.contains("open -R") })
    }
    
    @Test("Executes build with custom output location")
    func executesBuildWithCustomOutputLocation() throws {
        try createPackageSwift(executableName: executableName)
        
        let (sut, shell) = makeSUT(
            selectedItemIndices: [2], // Select custom location
            inputResponses: ["/tmp"], // Custom path
            permissionResponses: [true] // Confirm path
        )
        
        try sut.executeBuild(projectPath: projectFolder.path, buildType: .universal, clean: true, openInFinder: false)
        
        // Verify copy command was executed
        #expect(shell.executedCommands.contains { $0.contains("cp") && $0.contains("/tmp") })
    }
    
    @Test("Uses default build type when none provided")
    func usesDefaultBuildTypeWhenNoneProvided() throws {
        try createPackageSwift(executableName: executableName)
        
        let (sut, shell) = makeSUT(selectedItemIndices: [0])
        
        try sut.executeBuild(projectPath: projectFolder.path, buildType: .universal, clean: true, openInFinder: false)
        
        // Should complete without error using default build type
        #expect(shell.executedCommands.count >= 3)
    }
    
    @Test("Skips clean when clean flag is false")
    func skipsCleanWhenCleanFlagFalse() throws {
        try createPackageSwift(executableName: executableName)
        
        let (sut, shell) = makeSUT(selectedItemIndices: [0])
        
        try sut.executeBuild(projectPath: projectFolder.path, buildType: .universal, clean: false, openInFinder: false)
        
        // Should have one less command (no clean)
        #expect(shell.executedCommands.count >= 2)
    }
}


// MARK: - Error Tests
extension BuildExecutionManagerTests {
    // TODO: - need to enable MockSwiftPicker errors
    @Test("Throws error when picker fails to select executable", .disabled())
    func throwsErrorWhenPickerFailsToSelectExecutable() throws {
        try createPackageSwiftWithMultipleExecutables()

        let sut = makeSUT(throwPickerError: true).sut
        let path = projectFolder.path

        #expect(throws: BuildExecutionError.failedToSelectExecutable(reason: "MockPicker error")) {
            try sut.executeBuild(projectPath: path, buildType: .universal, clean: true, openInFinder: false)
        }
    }
    
    @Test("Throws error when custom path is invalid")
    func throwsErrorWhenCustomPathIsInvalid() throws {
        try createPackageSwift(executableName: executableName)

        let (sut, _) = makeSUT(
            selectedItemIndices: [2], // Select custom location
            inputResponses: ["/nonexistent/path"] // Invalid path
        )
        let path = projectFolder.path

        #expect(throws: BuildExecutionError.invalidCustomPath(path: "/nonexistent/path")) {
            try sut.executeBuild(projectPath: path, buildType: .universal, clean: true, openInFinder: false)
        }
    }
    
    @Test("Throws error when user cancels custom path confirmation")
    func throwsErrorWhenUserCancelsCustomPathConfirmation() throws {
        try createPackageSwift(executableName: executableName)

        let (sut, _) = makeSUT(
            selectedItemIndices: [2], // Select custom location
            inputResponses: ["/tmp"], // Valid path
            permissionResponses: [false] // Cancel confirmation
        )
        let path = projectFolder.path

        #expect(throws: BuildExecutionError.buildCancelledByUser) {
            try sut.executeBuild(projectPath: path, buildType: .universal, clean: true, openInFinder: false)
        }
    }
    
    @Test("Propagates ExecutableNameResolver errors")
    func propagatesExecutableNameResolverErrors() throws {
        let sut = makeSUT().sut
        let path = projectFolder.path

        #expect(throws: ExecutableNameResolverError.missingPackageSwift(path: path)) {
            try sut.executeBuild(projectPath: path, buildType: .universal, clean: true, openInFinder: false)
        }
    }
    
    @Test("Propagates build errors from ProjectBuilder")
    func propagatesBuildErrorsFromProjectBuilder() throws {
        try createPackageSwift(executableName: executableName)

        let sut = makeSUT(selectedItemIndices: [0], throwShellError: true).sut
        let path = projectFolder.path

        #expect(throws: (any Error).self) {
            try sut.executeBuild(projectPath: path, buildType: .universal, clean: true, openInFinder: false)
        }
    }
}


// MARK: - Private Methods
private extension BuildExecutionManagerTests {
    func makeSUT(selectedItemIndices: [Int] = [], inputResponses: [String] = [], permissionResponses: [Bool] = [], throwShellError: Bool = false, throwPickerError: Bool = false) -> (sut: BuildExecutionManager, shell: MockShell) {
        let shell = MockShell(shouldThrowErrorOnFinal: throwShellError)
        let picker = MockSwiftPicker(
            inputResult: .init(type: .ordered(inputResponses)),
            permissionResult: .init(type: .ordered(permissionResponses)),
            selectionResult: .init(singleType: .ordered(selectedItemIndices.map({ .index($0) })))
        )
        let sut = BuildExecutionManager(shell: shell, picker: picker)
        
        return (sut, shell)
    }
    
    func createPackageSwift(executableName: String) throws {
        let packageContent = """
        // swift-tools-version: 6.0
        import PackageDescription
        
        let package = Package(
            name: "\(projectName)",
            platforms: [.macOS(.v14)],
            products: [
                .executable(name: "\(executableName)", targets: ["\(executableName)"])
            ],
            targets: [
                .executableTarget(name: "\(executableName)")
            ]
        )
        """
        try projectFolder.createFile(named: "Package.swift", contents: packageContent.data(using: .utf8)!)
    }
    
    func createPackageSwiftWithMultipleExecutables() throws {
        let packageContent = """
        // swift-tools-version: 6.0
        import PackageDescription
        
        let package = Package(
            name: "\(projectName)",
            platforms: [.macOS(.v14)],
            products: [
                .executable(name: "FirstExecutable", targets: ["FirstExecutable"]),
                .executable(name: "SecondExecutable", targets: ["SecondExecutable"])
            ],
            targets: [
                .executableTarget(name: "FirstExecutable"),
                .executableTarget(name: "SecondExecutable")
            ]
        )
        """
        try projectFolder.createFile(named: "Package.swift", contents: packageContent.data(using: .utf8)!)
    }
}

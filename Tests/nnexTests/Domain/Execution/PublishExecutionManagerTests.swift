//
//  PublishExecutionManagerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Testing
import Foundation
import NnShellKit
import NnexSharedTestHelpers
import NnexKit
@testable import nnex
@preconcurrency import Files

final class PublishExecutionManagerTests {
    private let projectFolder: Folder
    private let tapFolder: Folder
    private let projectName = "testProject-publishManager"
    private let tapName = "testTap"
    private let executableName = "testExecutable"
    
    init() throws {
        let tempFolder = Folder.temporary
        self.projectFolder = try tempFolder.createSubfolder(named: "\(projectName)-\(UUID().uuidString)")
        self.tapFolder = try tempFolder.createSubfolder(named: "homebrew-\(tapName)-\(UUID().uuidString)")
    }
    
    deinit {
        deleteFolderContents(projectFolder)
        deleteFolderContents(tapFolder)
        try? projectFolder.delete()
        try? tapFolder.delete()
    }
}


// MARK: - Tests
extension PublishExecutionManagerTests {
    @Test("Successfully executes publish with existing formula")
    func successfullyExecutesPublishWithExistingFormula() throws {
        try createPackageSwift()
        
        let factory = MockContextFactory(
            runResults: [
                "", // git status --porcelain (clean)
                "", // Clean project
                "", // Build arm64
                "", // Strip arm64  
                "", // Build x86_64
                "", // Strip x86_64
                "", // tar command for arm64
                "abc123def456  /path/to/binary", // shasum for arm64
                "", // tar command for x86_64
                "abc123def456  /path/to/binary", // shasum for x86_64
                "asset1.tar.gz\nasset2.tar.gz" // gh release view assets
            ],
            selectedItemIndices: [],
            inputResponses: [],
            permissionResponses: [false] // Don't commit formula to GitHub
        )
        
        let context = try factory.makeContext()
        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        let existingFormula = SwiftDataFormula(
            name: executableName,
            details: "Test formula",
            homepage: "https://github.com/test/repo",
            license: "MIT",
            localProjectPath: projectFolder.path,
            uploadType: .binary,
            testCommand: nil,
            extraBuildArgs: []
        )
        
        try context.saveNewTap(existingTap)
        try context.saveNewFormula(existingFormula, in: existingTap)
        
        let sut = try makeSUT(factory: factory, context: context)
        
        try sut.executePublish(
            projectFolder: projectFolder,
            version: .version("2.0.0"),
            buildType: BuildType.universal,
            notes: nil as String?,
            notesFile: nil as String?,
            message: nil as String?,
            skipTests: true
        )
    }
    
    @Test("Successfully executes publish with new formula creation")
    func successfullyExecutesPublishWithNewFormulaCreation() throws {
        try createPackageSwift()
        
        let factory = MockContextFactory(
            runResults: [
                "", // git status --porcelain (clean)
                "", // Clean project
                "", // Build arm64
                "", // Strip arm64  
                "", // Build x86_64
                "", // Strip x86_64
                "", // tar command for arm64
                "abc123def456  /path/to/binary", // shasum for arm64
                "", // tar command for x86_64
                "abc123def456  /path/to/binary", // shasum for x86_64
                "asset1.tar.gz\nasset2.tar.gz" // gh release view assets
            ],
            selectedItemIndices: [0, 0], // Select tap, select no tests
            inputResponses: ["Test formula description"], // Formula description
            permissionResponses: [true, false] // Create new formula, don't commit to GitHub
        )
        
        let context = try factory.makeContext()
        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        
        try context.saveNewTap(existingTap)
        
        let sut = try makeSUT(factory: factory, context: context)
        
        try sut.executePublish(
            projectFolder: projectFolder,
            version: .version("2.0.0"),
            buildType: BuildType.universal,
            notes: nil as String?,
            notesFile: nil as String?,
            message: nil as String?,
            skipTests: true
        )
    }
    
    @Test("Commits and pushes formula when user chooses to")
    func commitsAndPushesFormulaWhenUserChooses() throws {
        try createPackageSwift()
        
        let factory = MockContextFactory(
            runResults: [
                "", // git status --porcelain (clean)
                "", // Clean project
                "", // Build arm64
                "", // Strip arm64  
                "", // Build x86_64
                "", // Strip x86_64
                "", // tar command for arm64
                "abc123def456  /path/to/binary", // shasum for arm64
                "", // tar command for x86_64
                "abc123def456  /path/to/binary", // shasum for x86_64
                "asset1.tar.gz\nasset2.tar.gz", // gh release view assets
                "", // git add
                "", // git commit
                "" // git push
            ],
            selectedItemIndices: [],
            inputResponses: ["Test commit message"], // Commit message
            permissionResponses: [true] // Commit and push to GitHub
        )
        
        let context = try factory.makeContext()
        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        let existingFormula = SwiftDataFormula(
            name: executableName,
            details: "Test formula",
            homepage: "https://github.com/test/repo",
            license: "MIT",
            localProjectPath: projectFolder.path,
            uploadType: .binary,
            testCommand: nil,
            extraBuildArgs: []
        )
        
        try context.saveNewTap(existingTap)
        try context.saveNewFormula(existingFormula, in: existingTap)
        
        let sut = try makeSUT(factory: factory, context: context)
        
        try sut.executePublish(
            projectFolder: projectFolder,
            version: .version("2.0.0"),
            buildType: BuildType.universal,
            notes: nil as String?,
            notesFile: nil as String?,
            message: nil as String?,
            skipTests: true
        )
    }
    
    @Test("Uses provided commit message instead of asking user")
    func usesProvidedCommitMessage() throws {
        try createPackageSwift()
        
        let factory = MockContextFactory(
            runResults: [
                "", // git status --porcelain (clean)
                "", // Clean project
                "", // Build arm64
                "", // Strip arm64  
                "", // Build x86_64
                "", // Strip x86_64
                "", // tar command for arm64
                "abc123def456  /path/to/binary", // shasum for arm64
                "", // tar command for x86_64
                "abc123def456  /path/to/binary", // shasum for x86_64
                "asset1.tar.gz\nasset2.tar.gz" // gh release view assets
            ]
        )
        
        let context = try factory.makeContext()
        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        let existingFormula = SwiftDataFormula(
            name: executableName,
            details: "Test formula",
            homepage: "https://github.com/test/repo",
            license: "MIT",
            localProjectPath: projectFolder.path,
            uploadType: .binary,
            testCommand: nil,
            extraBuildArgs: []
        )
        
        try context.saveNewTap(existingTap)
        try context.saveNewFormula(existingFormula, in: existingTap)
        
        let sut = try makeSUT(factory: factory, context: context)
        
        try sut.executePublish(
            projectFolder: projectFolder,
            version: .version("2.0.0"),
            buildType: BuildType.universal,
            notes: nil,
            notesFile: nil,
            message: "Provided commit message",
            skipTests: true
        )
    }
}


// MARK: - Error Tests
extension PublishExecutionManagerTests {
    @Test("Throws error when there are uncommitted changes")
    func throwsErrorWhenUncommittedChanges() throws {
        try createPackageSwift()
        
        let factory = MockContextFactory(
            runResults: ["M modified_file.swift"] // Uncommitted changes present
        )
        
        let context = try factory.makeContext()
        let sut = try makeSUT(factory: factory, context: context)
        
        #expect(throws: PublishExecutionError.uncommittedChanges) {
            try sut.executePublish(
                projectFolder: projectFolder,
                version: .version("2.0.0"),
                buildType: BuildType.universal,
                notes: nil,
                notesFile: nil,
                message: nil,
                skipTests: true
            )
        }
    }
    
    @Test("Throws error when GitHub CLI is not available")
    func throwsErrorWhenGitHubCLINotAvailable() throws {
        try createPackageSwift()
        
        let factory = MockContextFactory(
            gitHandler: MockGitHandler(ghIsInstalled: false)
        )
        
        let context = try factory.makeContext()
        let sut = try makeSUT(factory: factory, context: context)
        
        #expect(throws: (any Error).self) {
            try sut.executePublish(
                projectFolder: projectFolder,
                version: nil as ReleaseVersionInfo?,
                buildType: BuildType.universal,
                notes: nil as String?,
                notesFile: nil as String?,
                message: nil as String?,
                skipTests: true
            )
        }
    }
    
    @Test("Propagates build errors from PublishUtilities")
    func propagatesBuildErrors() throws {
        try createPackageSwift()
        
        let factory = MockContextFactory(
            runResults: [
                "", // git status --porcelain (no uncommitted changes)
                "v1.0.0\n", // git tag --list
            ],
            shell: MockShell(results: ["", ""], shouldThrowError: true) // Make build fail
        )
        
        let context = try factory.makeContext()
        let existingTap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        let existingFormula = SwiftDataFormula(
            name: executableName,
            details: "Test formula",
            homepage: "https://github.com/test/repo",
            license: "MIT",
            localProjectPath: projectFolder.path,
            uploadType: .binary,
            testCommand: nil,
            extraBuildArgs: []
        )
        
        try context.saveNewTap(existingTap)
        try context.saveNewFormula(existingFormula, in: existingTap)
        
        let sut = try makeSUT(factory: factory, context: context)
        
        #expect(throws: (any Error).self) {
            try sut.executePublish(
                projectFolder: projectFolder,
                version: nil as ReleaseVersionInfo?,
                buildType: BuildType.universal,
                notes: nil as String?,
                notesFile: nil as String?,
                message: nil as String?,
                skipTests: true
            )
        }
    }
}


// MARK: - Private Methods
private extension PublishExecutionManagerTests {
    func makeSUT(factory: MockContextFactory, context: NnexContext) throws -> PublishExecutionManager {
        let shell = factory.makeShell()
        let picker = factory.makePicker()
        let gitHandler = factory.makeGitHandler()
        let trashHandler = factory.makeTrashHandler()
        let publishInfoLoader = PublishInfoLoader(
            shell: shell,
            picker: picker,
            projectFolder: projectFolder,
            context: context,
            gitHandler: gitHandler,
            skipTests: true
        )
        
        return PublishExecutionManager(
            shell: shell,
            picker: picker,
            gitHandler: gitHandler,
            publishInfoLoader: publishInfoLoader,
            context: context,
            trashHandler: trashHandler,
            aiReleaseEnabled: false
        )
    }
    
    func createPackageSwift() throws {
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
}

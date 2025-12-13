////
////  PublishExecutionManagerTests.swift
////  nnex
////
////  Created by Nikolai Nobadi on 8/26/25.
////
//
//import NnexKit
//import Testing
//import Foundation
//import NnShellTesting
//import NnexSharedTestHelpers
//@testable import nnex
//@preconcurrency import Files
//
//@MainActor
//final class PublishExecutionManagerTests: BasePublishTestSuite {
//    private let projectName = "testProject-publishManager"
//    private let tapName = "testTap"
//    private let executableName = "testExecutable"
//    
//    init() throws {
//        try super.init(tapName: tapName, projectName: projectName)
//    }
//}
//
//
//// MARK: - Tests
//extension PublishExecutionManagerTests {
//    @Test("Successfully executes publish with existing formula")
//    func successfullyExecutesPublishWithExistingFormula() throws {
//        try createPackageSwift()
//        
//        let projectPath = projectFolder.path
//        let armArchivePath = "\(projectPath).build/arm64-apple-macosx/release/\(executableName)-arm64.tar.gz"
//        let intelArchivePath = "\(projectPath).build/x86_64-apple-macosx/release/\(executableName)-x86_64.tar.gz"
//        let commandResults: [String: String] = [
//            "swift build -c release --arch arm64 -Xswiftc -Osize -Xswiftc -wmo -Xswiftc -gnone -Xswiftc -cross-module-optimization -Xlinker -dead_strip_dylibs --package-path \(projectPath) ": "",
//            "swift build -c release --arch x86_64 -Xswiftc -Osize -Xswiftc -wmo -Xswiftc -gnone -Xswiftc -cross-module-optimization -Xlinker -dead_strip_dylibs --package-path \(projectPath) ": "",
//            "cd \"\(projectPath).build/arm64-apple-macosx/release\" && tar -czf \"\(executableName)-arm64.tar.gz\" \"\(executableName)\"": "",
//            "shasum -a 256 \"\(armArchivePath)\"": "abc123def456  \(armArchivePath)",
//            "cd \"\(projectPath).build/x86_64-apple-macosx/release\" && tar -czf \"\(executableName)-x86_64.tar.gz\" \"\(executableName)\"": "",
//            "shasum -a 256 \"\(intelArchivePath)\"": "abc123def456  \(intelArchivePath)",
//            "gh release view --json assets": "asset1.tar.gz\nasset2.tar.gz"
//        ]
//        
//        let factory = MockContextFactory(
//            commandResults: commandResults,
//            selectedItemIndices: [],
//            inputResponses: [
//                "formula details",
//                "release notes"
//            ],
//            permissionResponses: [
//                true, // create a new formula
//                false // Don't commit formula to GitHub
//            ]
//        )
//        
//        let store = MockHomebrewTapStore(
//            taps: [
//                HomebrewTap(
//                    name: tapName,
//                    localPath: tapFolder.path,
//                    remotePath: "",
//                    formulas: [
//                        HomebrewFormula(
//                            name: executableName,
//                            details: "Test formula",
//                            homepage: "https://github.com/test/repo",
//                            license: "MIT",
//                            localProjectPath: projectFolder.path,
//                            uploadType: .binary,
//                            testCommand: nil,
//                            extraBuildArgs: []
//                        )
//                    ]
//                )
//            ]
//        )
//        
//        let sut = try makeSUT(factory: factory, store: store)
//        
//        try sut.executePublish(
//            projectFolder: FilesDirectoryAdapter(folder: projectFolder),
//            version: .version("2.0.0"),
//            buildType: BuildType.universal,
//            notes: nil as String?,
//            notesFile: nil as String?,
//            message: nil as String?,
//            skipTests: true
//        )
//    }
//    
//    @Test("Successfully executes publish with new formula creation")
//    func successfullyExecutesPublishWithNewFormulaCreation() throws {
//        try createPackageSwift()
//        
//        let projectPath = projectFolder.path
//        let armArchivePath = "\(projectPath).build/arm64-apple-macosx/release/\(executableName)-arm64.tar.gz"
//        let intelArchivePath = "\(projectPath).build/x86_64-apple-macosx/release/\(executableName)-x86_64.tar.gz"
//        
//        let commandResults: [String: String] = [
//            "shasum -a 256 \"\(armArchivePath)\"": "abc123def456  \(armArchivePath)",
//            "shasum -a 256 \"\(intelArchivePath)\"": "abc123def456  \(intelArchivePath)",
//            "gh release view --json assets": "asset1.tar.gz\nasset2.tar.gz"
//        ]
//        
//        let factory = MockContextFactory(
//            commandResults: commandResults,
//            selectedItemIndices: [0, 0], // Select tap, select no tests
//            inputResponses: [
//                "formula details",
//                "release notes"
//            ],
//            permissionResponses: [
//                true, // create a new formula
//                false // Don't commit formula to GitHub
//            ]
//        )
//        
//        let store = MockHomebrewTapStore(
//            taps: [
//                HomebrewTap(name: tapName, localPath: tapFolder.path, remotePath: "", formulas: [])
//            ]
//        )
//        
//        let sut = try makeSUT(factory: factory, store: store)
//        
//        try sut.executePublish(
//            projectFolder: FilesDirectoryAdapter(folder: projectFolder),
//            version: .version("2.0.0"),
//            buildType: BuildType.universal,
//            notes: nil as String?,
//            notesFile: nil as String?,
//            message: nil as String?,
//            skipTests: true
//        )
//    }
//    
//    @Test("Commits and pushes formula when user chooses to")
//    func commitsAndPushesFormulaWhenUserChooses() throws {
//        try createPackageSwift()
//        
//        let projectPath = projectFolder.path
//        let armArchivePath = "\(projectPath).build/arm64-apple-macosx/release/\(executableName)-arm64.tar.gz"
//        let intelArchivePath = "\(projectPath).build/x86_64-apple-macosx/release/\(executableName)-x86_64.tar.gz"
//        
//        let commandResults: [String: String] = [
//            "shasum -a 256 \"\(armArchivePath)\"": "abc123def456  \(armArchivePath)",
//            "shasum -a 256 \"\(intelArchivePath)\"": "abc123def456  \(intelArchivePath)",
//            "gh release view --json assets": "asset1.tar.gz\nasset2.tar.gz"
//            // Git commands will be handled by MockGitHandler, not shell commands
//        ]
//        
//        let factory = MockContextFactory(
//            commandResults: commandResults,
//            selectedItemIndices: [],
//            inputResponses: [
//                "release notes",
//                "Test commit message" // Commit message
//            ],
//            permissionResponses: [true] // Commit and push to GitHub
//        )
//        
//        let store = MockHomebrewTapStore(
//            taps: [
//                HomebrewTap(
//                    name: tapName,
//                    localPath: tapFolder.path,
//                    remotePath: "",
//                    formulas: [
//                        HomebrewFormula(
//                            name: executableName,
//                            details: "Test formula",
//                            homepage: "https://github.com/test/repo",
//                            license: "MIT",
//                            localProjectPath: projectFolder.path,
//                            uploadType: .binary,
//                            testCommand: nil,
//                            extraBuildArgs: []
//                        )
//                    ]
//                )
//            ]
//        )
//        
//        let sut = try makeSUT(factory: factory, store: store)
//        
//        try sut.executePublish(
//            projectFolder: FilesDirectoryAdapter(folder: projectFolder),
//            version: .version("2.0.0"),
//            buildType: BuildType.universal,
//            notes: nil as String?,
//            notesFile: nil as String?,
//            message: nil as String?,
//            skipTests: true
//        )
//    }
//    
//    @Test("Uses provided commit message instead of asking user")
//    func usesProvidedCommitMessage() throws {
//        try createPackageSwift()
//        
//        let projectPath = projectFolder.path
//        let armArchivePath = "\(projectPath).build/arm64-apple-macosx/release/\(executableName)-arm64.tar.gz"
//        let intelArchivePath = "\(projectPath).build/x86_64-apple-macosx/release/\(executableName)-x86_64.tar.gz"
//        
//        let commandResults: [String: String] = [
//            "shasum -a 256 \"\(armArchivePath)\"": "abc123def456  \(armArchivePath)",
//            "shasum -a 256 \"\(intelArchivePath)\"": "abc123def456  \(intelArchivePath)",
//            "gh release view --json assets": "asset1.tar.gz\nasset2.tar.gz"
//        ]
//        
//        let factory = MockContextFactory(
//            commandResults: commandResults,
//            inputResponses: [
//                "formula details",
//                "release notes"
//            ],
//            permissionResponses: [
//                true // create new formula
//            ]
//        )
//        
//        let store = MockHomebrewTapStore(
//            taps: [
//                HomebrewTap(
//                    name: tapName,
//                    localPath: tapFolder.path,
//                    remotePath: "",
//                    formulas: [
//                        HomebrewFormula(
//                            name: executableName,
//                            details: "Test formula",
//                            homepage: "https://github.com/test/repo",
//                            license: "MIT",
//                            localProjectPath: projectFolder.path,
//                            uploadType: .binary,
//                            testCommand: nil,
//                            extraBuildArgs: []
//                        )
//                    ]
//                )
//            ]
//        )
//        
//        let sut = try makeSUT(factory: factory, store: store)
//        
//        try sut.executePublish(
//            projectFolder: FilesDirectoryAdapter(folder: projectFolder),
//            version: .version("2.0.0"),
//            buildType: BuildType.universal,
//            notes: nil,
//            notesFile: nil,
//            message: "Provided commit message",
//            skipTests: true
//        )
//    }
//}
//
//
//// MARK: - Error Tests
//extension PublishExecutionManagerTests {
//    @Test("Throws error when there are uncommitted changes")
//    func throwsErrorWhenUncommittedChanges() throws {
//        try createPackageSwift()
//        
//        let projectPath = projectFolder.path
//        let commandResults: [String: String] = [
//            "cd \"\(projectPath)\" && git status --porcelain": "M modified_file.swift" // Uncommitted changes present
//        ]
//        
//        let factory = MockContextFactory(
//            commandResults: commandResults
//        )
//        
//        let folder = projectFolder
//        let store = MockHomebrewTapStore(taps: [])
//        let sut = try makeSUT(factory: factory, store: store)
//        
//        #expect(throws: PublishExecutionError.uncommittedChanges) {
//            try sut.executePublish(
//                projectFolder: FilesDirectoryAdapter(folder: folder),
//                version: .version("2.0.0"),
//                buildType: BuildType.universal,
//                notes: nil,
//                notesFile: nil,
//                message: nil,
//                skipTests: true
//            )
//        }
//    }
//    
//    @Test("Throws error when GitHub CLI is not available")
//    func throwsErrorWhenGitHubCLINotAvailable() throws {
//        try createPackageSwift()
//        
//        let factory = MockContextFactory(
//            gitHandler: MockGitHandler(ghIsInstalled: false)
//        )
//        
//        let folder = FilesDirectoryAdapter(folder: projectFolder)
//        let store = MockHomebrewTapStore(taps: [])
//        let sut = try makeSUT(factory: factory, store: store)
//        
//        #expect(throws: (any Error).self) {
//            try sut.executePublish(
//                projectFolder: folder,
//                version: nil as ReleaseVersionInfo?,
//                buildType: BuildType.universal,
//                notes: nil as String?,
//                notesFile: nil as String?,
//                message: nil as String?,
//                skipTests: true
//            )
//        }
//    }
//    
//    @Test("Propagates build errors from PublishUtilities")
//    func propagatesBuildErrors() throws {
//        try createPackageSwift()
//        
//        let factory = MockContextFactory(shell: MockShell(shouldThrowErrorOnFinal: true))
//        let store = MockHomebrewTapStore(
//            taps: [
//                HomebrewTap(
//                    name: tapName,
//                    localPath: tapFolder.path,
//                    remotePath: "",
//                    formulas: [
//                        HomebrewFormula(
//                            name: executableName,
//                            details: "Test formula",
//                            homepage: "https://github.com/test/repo",
//                            license: "MIT",
//                            localProjectPath: projectFolder.path,
//                            uploadType: .binary,
//                            testCommand: nil,
//                            extraBuildArgs: []
//                        )
//                    ]
//                )
//            ]
//        )
//        
//        let folder = projectFolder
//        let sut = try makeSUT(factory: factory, store: store)
//        
//        #expect(throws: (any Error).self) {
//            try sut.executePublish(
//                projectFolder: FilesDirectoryAdapter(folder: folder),
//                version: nil as ReleaseVersionInfo?,
//                buildType: BuildType.universal,
//                notes: nil as String?,
//                notesFile: nil as String?,
//                message: nil as String?,
//                skipTests: true
//            )
//        }
//    }
//}
//
//
//// MARK: - Private Methods
//private extension PublishExecutionManagerTests {
//    func makeSUT(factory: MockContextFactory, store: MockHomebrewTapStore) throws -> PublishExecutionManager {
//        let shell = factory.makeShell()
//        let picker = factory.makePicker()
//        let gitHandler = factory.makeGitHandler()
//        let fileSystem = factory.makeFileSystem()
//        let folderBrowser = factory.makeFolderBrowser(picker: picker, fileSystem: fileSystem)
//        let folderAdapter = FilesDirectoryAdapter(folder: projectFolder)
//        let publishInfoLoader = PublishInfoLoader(
//            shell: shell,
//            picker: picker,
//            gitHandler: gitHandler,
//            store: store,
//            projectFolder: folderAdapter,
//            skipTests: true
//        )
//        
//        return .init(shell: shell, picker: picker, gitHandler: gitHandler, fileSystem: fileSystem, folderBrowser: folderBrowser, publishInfoLoader: publishInfoLoader)
//    }
//    
//    func createPackageSwift() throws {
//        try super.createPackageSwift(packageName: projectName, executableName: executableName)
//    }
//}

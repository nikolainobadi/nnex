// BuildTests.swift
// nnex
//
// Created by Nikolai Nobadi on 4/21/25.

import NnexKit
import Testing
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor
final class BuildTests {
    private let projectFolder: Folder
    private let executableName = "testExecutable"
    private let binaryPath = "/tmp/testExecutable"

    init() throws {
        let tempFolder = Folder.temporary
        self.projectFolder = try tempFolder.createSubfolder(named: "TestProject")
    }

    deinit {
        deleteFolderContents(projectFolder)
    }
}

// MARK: - Unit Tests
extension BuildTests {
    @Test("Builds project and outputs binary path")
    func successfulBuildOutputsPath() throws {
        let shell = MockShell(runResults: [])
        let factory = MockContextFactory(runResults: [], shell: shell)
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)

        #expect(output.contains("New binary was built at"))
    }

    @Test("Opens binary in Finder when openInFinder flag is set")
    func openBinaryInFinder() throws {
        let shell = MockShell(runResults: [])
        let factory = MockContextFactory(runResults: [], shell: shell)
        
        try createPackageManifest(name: executableName)
        
        _ = try runCommand(factory, openInFinder: true)

        #expect(shell.printedCommands.contains { $0.contains("open -R") })
    }
    
    @Test("Fails when Package.swift is missing")
    func failsWithoutPackageManifest() throws {
        let factory = MockContextFactory()

        #expect(throws: (any Error).self) {
            try runCommand(factory)
        }
    }
}

// MARK: - Helpers
private extension BuildTests {
    func runCommand(_ factory: MockContextFactory, openInFinder: Bool = false) throws -> String {
        var args = ["build", "-p", projectFolder.path]
        if openInFinder {
            args.append("-o")
        }
        return try Nnex.testRun(contextFactory: factory, args: args)
    }

    func createPackageManifest(name: String) throws {
        let manifest = """
        // swift-tools-version:5.9
        import PackageDescription

        let package = Package(
            name: "\(name)",
            products: [
                .executable(name: "\(name)", targets: ["\(name)"])
            ],
            targets: [
                .target(name: "\(name)")
            ]
        )
        """
        try projectFolder.createFile(named: "Package.swift").write(manifest)
    }
}

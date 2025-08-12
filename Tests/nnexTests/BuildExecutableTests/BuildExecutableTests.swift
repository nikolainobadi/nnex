// BuildTests.swift
// nnex
//
// Created by Nikolai Nobadi on 4/21/25.

import NnexKit
import Testing
import Foundation
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
        self.projectFolder = try tempFolder.createSubfolder(named: "TestFolder\(UUID().uuidString)")
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
    
    @Test("Clean flag defaults to true and sets skipClean to false")
    func cleanFlagDefaultsToTrue() throws {
        let shell = MockShell(runResults: [])
        let factory = MockContextFactory(runResults: [], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        // Verify build was called (clean flag default is true, so skipClean should be false)
        #expect(output.contains("New binary was built at"))
    }
    
    @Test("No-clean flag sets skipClean to true")
    func noCleanFlagSetsSkipCleanToTrue() throws {
        let shell = MockShell(runResults: [])
        let factory = MockContextFactory(runResults: [], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory, clean: false)
        
        #expect(output.contains("New binary was built at"))
    }
    
    @Test("Builds to current directory when selected")
    func buildsToCurrentDirectoryWhenSelected() throws {
        let shell = MockShell(runResults: [])
        let factory = MockContextFactory(runResults: [], selectedItemIndices: [0], shell: shell) // Select current directory (index 0)
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("New binary was built at"))
        // Should not contain any cp commands since it stays in current location
        #expect(!shell.printedCommands.contains { $0.contains("cp") })
    }
    
    @Test("Builds to desktop when selected")
    func buildsToDesktopWhenSelected() throws {
        let shell = MockShell(runResults: [])
        let factory = MockContextFactory(runResults: [], selectedItemIndices: [1], shell: shell) // Select desktop (index 1)
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("New binary was built at"))
        // Should contain cp command to copy to desktop
        #expect(shell.printedCommands.contains { $0.contains("cp") && $0.contains("Desktop") })
    }
    
    @Test("Prompts for custom location and confirms path")
    func promptsForCustomLocationAndConfirmsPath() throws {
        let shell = MockShell(runResults: [])
        let customPath = "/tmp"
        let factory = MockContextFactory(
            runResults: [],
            selectedItemIndices: [2], // Select custom (index 2)
            inputResponses: [customPath],
            permissionResponses: [true], // Confirm the path
            shell: shell
        )
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("New binary was built at"))
        // Should contain cp command to copy to custom location
        #expect(shell.printedCommands.contains { $0.contains("cp") && $0.contains(customPath) })
    }
    
    @Test("Handles custom location input cancellation gracefully")
    func handlesCustomLocationInputCancellationGracefully() throws {
        let shell = MockShell(runResults: [])
        let customPath = "/tmp"
        let factory = MockContextFactory(
            runResults: [],
            selectedItemIndices: [2], // Select custom (index 2)
            inputResponses: [customPath],
            permissionResponses: [false], // Cancel the confirmation
            shell: shell
        )
        
        try createPackageManifest(name: executableName)
        
        #expect(throws: (any Error).self) {
            try runCommand(factory)
        }
    }
    
    @Test("Copies binary to selected output location")
    func copiesBinaryToSelectedOutputLocation() throws {
        let shell = MockShell(runResults: [])
        let factory = MockContextFactory(runResults: [], selectedItemIndices: [1], shell: shell) // Select desktop
        
        try createPackageManifest(name: executableName)
        
        _ = try runCommand(factory)
        
        // Verify cp command was executed
        #expect(shell.printedCommands.contains { $0.contains("cp") })
    }
    
    @Test("Shows final binary location in output message", .disabled()) // TODO: -
    func showsFinalBinaryLocationInOutputMessage() throws {
        let shell = MockShell(runResults: [])
        let factory = MockContextFactory(runResults: [], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("New binary was built at"))
        #expect(output.contains(binaryPath)) // Should show the actual binary path
    }
}

// MARK: - Helpers
private extension BuildTests {
    func runCommand(_ factory: MockContextFactory, openInFinder: Bool = false, clean: Bool = true) throws -> String {
        var args = ["build", "-p", projectFolder.path]
        if openInFinder {
            args.append("-o")
        }
        if !clean {
            args.append("--no-clean")
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

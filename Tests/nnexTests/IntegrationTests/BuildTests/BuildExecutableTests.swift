//
// BuildTests.swift
// nnex
//
// Created by Nikolai Nobadi on 4/21/25.

import NnexKit
import Testing
import Foundation
import NnShellTesting
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
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], shell: shell)
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)

        #expect(output.contains("builds"))
    }

    @Test("Opens binary in Finder when openInFinder flag is set")
    func openBinaryInFinder() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], shell: shell)
        
        try createPackageManifest(name: executableName)
        
        _ = try runCommand(factory, openInFinder: true)

        #expect(shell.executedCommand(containing: "open -R"))
    }
    
    @Test("Fails when Package.swift is missing")
    func failsWithoutPackageManifest() throws {
        let factory = MockContextFactory()

        do {
            try runCommand(factory)
            Issue.record("Expected an error to be thrown")
        } catch { }
    }
    
    @Test("Clean flag defaults to true and sets skipClean to false")
    func cleanFlagDefaultsToTrue() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(shell.executedCommand(containing: "clean"))
        #expect(output.contains("builds"))
    }
    
    @Test("No-clean flag sets skipClean to true")
    func noCleanFlagSetsSkipCleanToTrue() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory, clean: false)
        
        #expect(!shell.executedCommand(containing: "clean"))
        #expect(output.contains("builds"))
    }
    
    @Test("Builds to current directory when selected")
    func buildsToCurrentDirectoryWhenSelected() throws {
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [0], shell: shell) // Select current directory (index 0)
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("builds"))
        #expect(!shell.executedCommand(containing: "cp"))
    }
    
    @Test("Builds to desktop when selected", .disabled()) // TODO: -
    func buildsToDesktopWhenSelected() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [1], shell: shell) // Select desktop (index 1)
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("builds"))
        #expect(shell.executedCommand(containing: "cp"))
        #expect(shell.executedCommand(containing: "Desktop"))
    }
    
    @Test("Prompts for custom location and confirms path", .disabled()) // TODO: -
    func promptsForCustomLocationAndConfirmsPath() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let customPath = "/tmp"
        let customDirectory = MockDirectory(path: customPath)
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(
            runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"],
            selectedItemIndices: [2], // Select custom (index 2)
            inputResponses: [customPath],
            permissionResponses: [true], // Confirm the path
            shell: shell,
            browsedDirectory: customDirectory
        )
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("builds"))
        #expect(shell.executedCommand(containing: "cp"))
        #expect(shell.executedCommand(containing: customPath))
    }
    
    @Test("Handles custom location input cancellation gracefully")
    func handlesCustomLocationInputCancellationGracefully() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let customPath = "/tmp"
        let factory = MockContextFactory(
            runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"],
            selectedItemIndices: [2], // Select custom (index 2)
            inputResponses: [customPath],
            permissionResponses: [false], // Cancel the confirmation
            shell: MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        )
        
        try createPackageManifest(name: executableName)
        
        do {
            try runCommand(factory)
            Issue.record("Expected an error to be thrown")
        } catch { }
    }
    
    @Test("Copies binary to selected output location", .disabled()) // TODO: -
    func copiesBinaryToSelectedOutputLocation() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [1], shell: shell) // Select desktop
        
        try createPackageManifest(name: executableName)
        
        _ = try runCommand(factory)
        
        // Verify cp command was executed
        #expect(shell.executedCommands.contains { $0.contains("cp") })
    }
    
    @Test("Shows final binary location in output message")
    func showsFinalBinaryLocationInOutputMessage() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("builds"))
        #expect(output.contains("arm64")) // Should show architecture info
        #expect(output.contains("x86_64")) // Should show architecture info
    }
}

// MARK: - Helpers
private extension BuildTests {
    @discardableResult
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

// BuildTests.swift
// nnex
//
// Created by Nikolai Nobadi on 4/21/25.

import NnexKit
import Testing
import Foundation
import NnShellKit
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
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], shell: shell)
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)

        #expect(output.contains("Universal binary built:"))
    }

    @Test("Opens binary in Finder when openInFinder flag is set")
    func openBinaryInFinder() throws {
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], shell: shell)
        
        try createPackageManifest(name: executableName)
        
        _ = try runCommand(factory, openInFinder: true)

        #expect(shell.executedCommands.contains { $0.contains("open -R") })
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
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        // Verify build was called (clean flag default is true, so skipClean should be false)
        #expect(output.contains("Universal binary built:"))
    }
    
    @Test("No-clean flag sets skipClean to true")
    func noCleanFlagSetsSkipCleanToTrue() throws {
        // No-clean build results: build arm64, build x86_64, shasum arm, shasum intel (no clean command)
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory, clean: false)
        
        #expect(output.contains("Universal binary built:"))
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
        
        #expect(output.contains("Universal binary built:"))
        // Should not contain any cp commands since it stays in current location
        #expect(!shell.executedCommands.contains { $0.contains("cp") })
    }
    
    @Test("Builds to desktop when selected")
    func buildsToDesktopWhenSelected() throws {
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [1], shell: shell) // Select desktop (index 1)
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("Universal binary built:"))
        // Should contain cp command to copy to desktop
        #expect(shell.executedCommands.contains { $0.contains("cp") && $0.contains("Desktop") })
    }
    
    @Test("Prompts for custom location and confirms path")
    func promptsForCustomLocationAndConfirmsPath() throws {
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let customPath = "/tmp"
        let factory = MockContextFactory(
            runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"],
            selectedItemIndices: [2], // Select custom (index 2)
            inputResponses: [customPath],
            permissionResponses: [true], // Confirm the path
            shell: MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        )
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("Universal binary built:"))
        // Should contain cp command to copy to custom location
        let shell = factory.makeShell() as! MockShell
        #expect(shell.executedCommands.contains { $0.contains("cp") && $0.contains(customPath) })
    }
    
    @Test("Handles custom location input cancellation gracefully")
    func handlesCustomLocationInputCancellationGracefully() throws {
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
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
    
    @Test("Copies binary to selected output location")
    func copiesBinaryToSelectedOutputLocation() throws {
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
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
        // Universal build results: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shell = MockShell(results: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        let factory = MockContextFactory(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], selectedItemIndices: [0], shell: shell) // Select current directory
        
        try createPackageManifest(name: executableName)
        
        let output = try runCommand(factory)
        
        #expect(output.contains("Universal binary built:"))
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

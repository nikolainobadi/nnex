//
//  PublishUtilitiesTests.swift
//  NnexKitTests
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Testing
import Foundation
import NnShellTesting
import NnexSharedTestHelpers
@testable import NnexKit
@preconcurrency import Files

struct PublishUtilitiesTests {
    private let projectName = "testProject"
    private let projectPath = "/test/project/path"
    private let homepage = "https://github.com/user/testproject"
    private let license = "MIT"
    private let details = "A test project for unit testing"
    private let version = "1.0.0"
    private let sha256Output = "abc123def456  /path/to/binary"  // Shasum command output format
    private let sha256Value = "abc123def456"  // Just the hash value
    private let assetURL1 = "https://github.com/releases/download/v1.0.0/binary-universal.tar.gz"
    private let assetURL2 = "https://github.com/releases/download/v1.0.0/binary-intel.tar.gz"
}


// MARK: - buildBinary Tests (using ProjectBuilder directly since it doesn't require SwiftData)
extension PublishUtilitiesTests {
    @Test("Builds binary with universal build type")
    func buildsBinaryWithUniversalType() throws {
        let shell = MockShell(results: ["", "", "", sha256Output, sha256Output]) // clean, build arm64, build x86_64, sha256 commands
        let config = BuildConfig(projectName: projectName, projectPath: projectPath, buildType: .universal, extraBuildArgs: [], skipClean: false, testCommand: nil)
        let builder = ProjectBuilder(shell: shell, config: config)
        
        let result = try builder.build()
        
        // Should build for both architectures
        #expect(shell.executedCommands.count >= 3) // At least clean, build arm64, build x86_64
        
        switch result {
        case .multiple(let binaries):
            #expect(binaries.count == 2)
            #expect(binaries[.arm] != nil)
            #expect(binaries[.intel] != nil)
        case .single:
            Issue.record("Expected multiple binaries for universal build")
        }
    }
    
    @Test("Builds binary with custom extra build args")
    func buildsBinaryWithExtraBuildArgs() throws {
        let extraArgs = ["--verbose", "--enable-testing"]
        let shell = MockShell(results: ["", "", "", sha256Output, sha256Output])
        let config = BuildConfig(projectName: projectName, projectPath: projectPath, buildType: .universal, extraBuildArgs: extraArgs, skipClean: false, testCommand: nil)
        let builder = ProjectBuilder(shell: shell, config: config)
        
        _ = try builder.build()
        
        // Verify extra args are included in build commands
        let buildCommands = shell.executedCommands.filter { $0.contains("swift build") }
        for arg in extraArgs {
            #expect(buildCommands.contains { $0.contains(arg) })
        }
    }
    
    @Test("Skips tests when no test command provided")
    func skipsTestsWhenNoTestCommand() throws {
        let shell = MockShell(results: ["", "", "", sha256Output, sha256Output]) // No test command result needed
        let config = BuildConfig(projectName: projectName, projectPath: projectPath, buildType: .universal, extraBuildArgs: [], skipClean: false, testCommand: nil)
        let builder = ProjectBuilder(shell: shell, config: config)
        
        _ = try builder.build()
        
        #expect(!shell.executedCommands.contains { $0.contains("swift test") })
    }
    
    @Test("Runs tests when test command is provided")
    func runsTestsWhenTestCommandProvided() throws {
        let shell = MockShell(results: ["", "", "", "", sha256Output, sha256Output]) // Include test command result
        let config = BuildConfig(projectName: projectName, projectPath: projectPath, buildType: .universal, extraBuildArgs: [], skipClean: false, testCommand: .defaultCommand)
        let builder = ProjectBuilder(shell: shell, config: config)
        
        _ = try builder.build()
        
        #expect(shell.executedCommands.contains { $0.contains("swift test") })
    }
    
    @Test("Uses custom test command when provided")
    func usesCustomTestCommand() throws {
        let customTest = "xcodebuild test -scheme testScheme"
        let shell = MockShell(results: ["", "", "", "", sha256Output, sha256Output])
        let config = BuildConfig(projectName: projectName, projectPath: projectPath, buildType: .universal, extraBuildArgs: [], skipClean: false, testCommand: .custom(customTest))
        let builder = ProjectBuilder(shell: shell, config: config)
        
        _ = try builder.build()
        
        #expect(shell.executedCommands.contains { $0.contains(customTest) })
    }
}


// MARK: - createArchives Tests
extension PublishUtilitiesTests {
    @Test("Creates archive from single binary")
    func createsArchiveFromSingleBinary() throws {
        // Create temporary binary file for testing
        let tempFolder = try Folder.temporary.createSubfolder(named: "test-binary-\(UUID().uuidString)")
        defer { try? tempFolder.delete() }
        
        let binaryFile = try tempFolder.createFile(named: "testBinary")
        try binaryFile.write("fake binary content")
        
        let shell = MockShell(results: ["", sha256Output])  // tar command result, then shasum result
        let binaryOutput = BinaryOutput.single(binaryFile.path)
        
        let archives = try PublishUtilities.createArchives(from: binaryOutput, shell: shell)
        
        #expect(archives.count == 1)
        #expect(archives[0].sha256 == sha256Value)
        #expect(archives[0].originalPath == binaryFile.path)
    }
    
    @Test("Creates archives from multiple binaries")
    func createsArchivesFromMultipleBinaries() throws {
        // Create temporary binary files for testing
        let tempFolder = try Folder.temporary.createSubfolder(named: "test-binaries-\(UUID().uuidString)")
        defer { try? tempFolder.delete() }
        
        let armFile = try tempFolder.createFile(named: "armBinary")
        let intelFile = try tempFolder.createFile(named: "intelBinary")
        try armFile.write("fake arm binary content")
        try intelFile.write("fake intel binary content")
        
        let shell = MockShell(results: ["", sha256Output, "", sha256Output])  // tar, shasum, tar, shasum
        let binaryOutput = BinaryOutput.multiple([.arm: armFile.path, .intel: intelFile.path])
        let archives = try PublishUtilities.createArchives(from: binaryOutput, shell: shell)
        
        #expect(archives.count == 2)
        let archivePaths = archives.map { $0.originalPath }
        #expect(archivePaths.contains(armFile.path))
        #expect(archivePaths.contains(intelFile.path))
    }
    
    @Test("Handles shell command failure during archiving")
    func handlesShellCommandFailure() throws {
        // Create temporary binary file for testing
        let tempFolder = try Folder.temporary.createSubfolder(named: "test-binary-fail-\(UUID().uuidString)")
        defer { try? tempFolder.delete() }
        
        let binaryFile = try tempFolder.createFile(named: "testBinary")
        try binaryFile.write("fake binary content")
        
        let shell = MockShell(shouldThrowErrorOnFinal: true)
        let binaryOutput = BinaryOutput.single(binaryFile.path)
        
        #expect(throws: (any Error).self) {
            try PublishUtilities.createArchives(from: binaryOutput, shell: shell)
        }
    }
}


// MARK: - makeFormulaContent Tests (using FormulaContentGenerator directly)
extension PublishUtilitiesTests {
    @Test("Creates formula content for single binary")
    func createsFormulaContentForSingleBinary() throws {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: projectName,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            assetURL: assetURL1,
            sha256: sha256Value
        )

        #expect(content.contains(projectName.capitalized))
        #expect(content.contains(homepage))
        #expect(content.contains(license))
        #expect(content.contains(details))
        #expect(content.contains(sha256Value))
        #expect(content.contains(assetURL1))
    }

    @Test("Creates formula content for multiple binaries with ARM and Intel")
    func createsFormulaContentForMultipleBinaries() throws {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: projectName,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: assetURL1,
            armSHA256: "arm_sha256",
            intelURL: assetURL2,
            intelSHA256: "intel_sha256"
        )

        #expect(content.contains(projectName.capitalized))
        #expect(content.contains("arm_sha256"))
        #expect(content.contains("intel_sha256"))
        #expect(content.contains(assetURL1))
        #expect(content.contains(assetURL2))
    }

    @Test("Creates formula content for ARM-only binary")
    func createsFormulaContentForArmOnly() throws {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: projectName,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: assetURL1,
            armSHA256: "arm_sha256",
            intelURL: nil,
            intelSHA256: nil
        )

        #expect(content.contains(projectName.capitalized))
        #expect(content.contains("arm_sha256"))
        #expect(content.contains(assetURL1))
        // Should handle single ARM architecture case
        #expect(!content.contains("intel"))
    }

    @Test("Creates formula content for Intel-only binary")
    func createsFormulaContentForIntelOnly() throws {
        let content = FormulaContentGenerator.makeFormulaFileContent(
            name: projectName,
            details: details,
            homepage: homepage,
            license: license,
            version: version,
            armURL: nil,
            armSHA256: nil,
            intelURL: assetURL1,
            intelSHA256: "intel_sha256"
        )

        #expect(content.contains(projectName.capitalized))
        #expect(content.contains("intel_sha256"))
        #expect(content.contains(assetURL1))
        // Should handle single Intel architecture case
        #expect(!content.contains("arm"))
    }
}


// MARK: - Mock Types
private struct MockFormula {
    let name: String
    let details: String
    let homepage: String
    let license: String
    let localProjectPath: String
    let testCommand: CurrentSchema.TestCommand?
    let extraBuildArgs: [String]
}

// MARK: - Private Helpers
private extension PublishUtilitiesTests {
    func makeFormula(testCommand: CurrentSchema.TestCommand? = nil, extraBuildArgs: [String] = []) -> MockFormula {
        return MockFormula(
            name: projectName,
            details: details,
            homepage: homepage,
            license: license,
            localProjectPath: projectPath,
            testCommand: testCommand,
            extraBuildArgs: extraBuildArgs
        )
    }
}

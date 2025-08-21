//
//  ProjectBuilderTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Testing
import NnShellKit
@testable import NnexKit

struct ProjectBuilderTests {
    private let sha256 = "abc123def456"
    private let projectName = "TestProject"
    private let projectPath = "/path/to/project"
    private let extraArgs = ["extraArg"]
    private let customTestCommand = "swift test --filter SomeTests"
}

// MARK: - Unit Tests
extension ProjectBuilderTests {
    @Test("Successfully builds a universal binary")
    func buildUniversalBinary() throws {
        // Need results for: clean, build arm64, build x86_64, mkdir, lipo, strip, shasum
        let sut = makeSUT(runResults: ["", "", "", "", "", "", "\(sha256)  /path/to/binary"]).sut
        let result = try sut.discardableBuild()
        
        #expect(result.path.contains(projectPath))
        #expect(result.path.contains(projectName))
        #expect(result.sha256 == sha256, "Expected SHA-256 \(sha256), but got \(result.sha256)")
    }
    
    @Test("Throws error if build for architecture fails")
    func buildArchitectureFails() throws {
        let (sut, _) = makeSUT(throwShellError: true)
        
        #expect(throws: (any Error).self) {
            try sut.discardableBuild()
        }
    }
    
    @Test("Throws error if universal binary creation fails")
    func buildUniversalBinaryFails() throws {
        let (sut, _) = makeSUT(runResults: ["some/path"], throwShellError: true)
        
        #expect(throws: (any Error).self) {
            try sut.discardableBuild()
        }
    }
    
    @Test("Throws error if SHA-256 calculation fails")
    func sha256CalculationFails() throws {
        let (sut, _) = makeSUT(runResults: ["some/path"], throwShellError: true)
        
        #expect(throws: (any Error).self) {
            try sut.discardableBuild()
        }
    }
    
    @Test("Successfully builds an arm64 binary")
    func buildArm64Binary() throws {
        // Need results for: clean, build arm64, shasum
        let sut = makeSUT(buildType: .arm64, runResults: ["", "", "\(sha256)  /path/to/binary"]).sut
        let result = try sut.discardableBuild()
        
        #expect(result.path.contains(projectPath))
        #expect(result.path.contains("arm64-apple-macosx"))
        #expect(result.path.contains(projectName))
        #expect(result.sha256 == sha256, "Expected SHA-256 \(sha256), but got \(result.sha256)")
    }
    
    @Test("Successfully builds an x86_64 binary")
    func buildX86_64Binary() throws {
        // Need results for: clean, build x86_64, shasum
        let sut = makeSUT(buildType: .x86_64, runResults: ["", "", "\(sha256)  /path/to/binary"]).sut
        let result = try sut.discardableBuild()
        
        #expect(result.path.contains(projectPath))
        #expect(result.path.contains("x86_64-apple-macosx"))
        #expect(result.path.contains(projectName))
        #expect(result.sha256 == sha256, "Expected SHA-256 \(sha256), but got \(result.sha256)")
    }
    
    @Test("Successfully passes extra build arguments")
    func buildWithExtraArgs() throws {
        // Need results for: clean, build arm64, build x86_64, mkdir, lipo, strip, shasum
        let (sut, shell) = makeSUT(runResults: ["", "", "", "", "", "", "\(sha256)  /path/to/binary"])
        let result = try sut.build()
        let expectedCommandPart = extraArgs.joined(separator: " ")
        
        #expect(shell.executedCommands.contains { $0.contains(expectedCommandPart) })
        #expect(result.path.contains(projectPath))
        #expect(result.path.contains(projectName))
        #expect(result.sha256 == sha256, "Expected SHA-256 \(sha256), but got \(result.sha256)")
    }
    
    @Test("Runs default test command after build")
    func runsDefaultTestCommand() throws {
        // Need results for: clean, build arm64, build x86_64, mkdir, lipo, strip, shasum, test
        let (sut, shell) = makeSUT(runResults: ["", "", "", "", "", "", "\(sha256)  /path/to/binary", ""], testCommand: .defaultCommand)
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains("swift test") })
    }

    @Test("Runs custom test command after build")
    func runsCustomTestCommand() throws {
        // Need results for: clean, build arm64, build x86_64, mkdir, lipo, strip, shasum, test
        let (sut, shell) = makeSUT(runResults: ["", "", "", "", "", "", "\(sha256)  /path/to/binary", ""], testCommand: .custom(customTestCommand))
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains(customTestCommand) })
    }

    @Test("Skips running tests if no test command is provided")
    func skipsRunningTests() throws {
        // Need results for: clean, build arm64, build x86_64, mkdir, lipo, strip, shasum
        let (sut, shell) = makeSUT(runResults: ["", "", "", "", "", "", "\(sha256)  /path/to/binary"], testCommand: nil)
        
        try sut.discardableBuild()
        
        #expect(!shell.executedCommands.contains { $0.contains("swift test") })
        #expect(!shell.executedCommands.contains { $0.contains(customTestCommand) })
    }
    
    @Test("Includes cleaning by default")
    func includesCleaning() throws {
        // Need results for: clean, build arm64, build x86_64, mkdir, lipo, strip, shasum
        let (sut, shell) = makeSUT(runResults: ["", "", "", "", "", "", "\(sha256)  /path/to/binary"])
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains("swift package clean --package-path \(projectPath)") })
    }
    
    @Test("Skips cleaning when indicated")
    func skipsCleaning() throws {
        // Need results for: build arm64, build x86_64, mkdir, lipo, strip, shasum (no clean)
        let (sut, shell) = makeSUT(runResults: ["", "", "", "", "", "\(sha256)  /path/to/binary"], skipClean: true)
        
        try sut.discardableBuild()
        
        #expect(!shell.executedCommands.contains { $0.contains("swift package clean --package-path \(projectPath)") })
    }
}


// MARK: - SUT
private extension ProjectBuilderTests {
    func makeSUT(buildType: BuildType = .universal, runResults: [String] = [], throwShellError: Bool = false, testCommand: TestCommand? = nil, skipClean: Bool = false) -> (sut: ProjectBuilder, shell: MockShell) {
        let shell = MockShell(results: runResults, shouldThrowError: throwShellError)
        let config = BuildConfig(
            projectName: projectName,
            projectPath: projectPath,
            buildType: buildType,
            extraBuildArgs: extraArgs,
            skipClean: skipClean,
            testCommand: testCommand
        )
        
        let sut = ProjectBuilder(shell: shell, config: config)
        
        return (sut, shell)
    }
}


// MARK: - Extension Helpers
public extension ProjectBuilder {
    @discardableResult
    func discardableBuild() throws -> BinaryInfo {
        return try build()
    }
}

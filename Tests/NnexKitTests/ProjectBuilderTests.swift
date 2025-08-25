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

// MARK: - Success Tests
extension ProjectBuilderTests {
    @Test("Successfully builds a universal binary")
    func buildUniversalBinary() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let shellResults = [
            "", // clean
            "", // build arm64
            "", // build x86_64
            "\(armSha256)  /path/to/binary",
            "\(intelSha256)  /path/to/binary"
        ]
        
        let sut = makeSUT(runResults: shellResults).sut
        let result = try sut.discardableBuild()
        
        switch result {
        case .single:
            Issue.record("Expected .multiple BinaryOutput but found .single")
        case .multiple(let dict):
            for (key, info) in dict {
                let expectedSha256 = key == .arm ? armSha256 : intelSha256
                
                #expect(info.path.contains(projectPath))
                #expect(info.path.contains(projectName))
                #expect(info.sha256 == expectedSha256, "Expected SHA-256 \(expectedSha256), but got \(info.sha256)")
            }
        }
    }
    
    @Test("Successfully builds an single binary", arguments: [BuildType.arm64, BuildType.x86_64])
    func buildSingleBinary(buildType: BuildType) throws {
        let sut = makeSUT(buildType: buildType, runResults: ["", "", "\(sha256)  /path/to/binary"]).sut
        let result = try sut.discardableBuild()
        
        switch result {
        case .single(let info):
            #expect(info.path.contains(projectPath))
            #expect(info.path.contains("\(buildType.rawValue)-apple-macosx"))
            #expect(info.path.contains(projectName))
            #expect(info.sha256 == sha256, "Expected SHA-256 \(sha256), but got \(info.sha256)")
        case .multiple:
            Issue.record("Expected .single BinaryOutput but found .multiple")
        }
    }
    
    @Test("Successfully passes extra build arguments")
    func buildWithExtraArgs() throws {
        // Need results for: clean, build arm64, build x86_64, shasum arm, shasum intel, test
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary", ""])
        let result = try sut.discardableBuild()
        let expectedCommandPart = extraArgs.joined(separator: " ")
        
        #expect(shell.executedCommands.contains { $0.contains(expectedCommandPart) })
        
        switch result {
        case .single:
            Issue.record("Expected .multiple BinaryOutput but found .single")
        case .multiple(let dict):
            for (_, info) in dict {
                #expect(info.path.contains(projectPath))
                #expect(info.path.contains(projectName))
            }
        }
    }
    
    @Test("Runs default test command after build")
    func runsDefaultTestCommand() throws {
        // Need results for: clean, build arm64, build x86_64, shasum arm, shasum intel, test
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary", ""], testCommand: .defaultCommand)
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains("swift test") })
    }

    @Test("Runs custom test command after build")
    func runsCustomTestCommand() throws {
        // Need results for: clean, build arm64, build x86_64, shasum arm, shasum intel, test
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary", ""], testCommand: .custom(customTestCommand))
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains(customTestCommand) })
    }

    @Test("Skips running tests if no test command is provided")
    func skipsRunningTests() throws {
        // Need results for: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], testCommand: nil)
        
        try sut.discardableBuild()
        
        #expect(!shell.executedCommands.contains { $0.contains("swift test") })
        #expect(!shell.executedCommands.contains { $0.contains(customTestCommand) })
    }

    @Test("Custom command without flags gets required flags added")
    func customCommandWithoutFlags() throws {
        let baseCommand = "xcodebuild test -scheme nnex"
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary", ""], testCommand: .custom(baseCommand))
        
        try sut.discardableBuild()
        
        let testCommand = shell.executedCommands.first { $0.contains("xcodebuild") }
        #expect(testCommand?.contains("-quiet") == true)
        #expect(testCommand?.contains("-allowProvisioningUpdates") == true)
        #expect(testCommand?.contains(baseCommand) == true)
    }

    @Test("Custom command with one flag gets missing flag added")
    func customCommandWithOneFlag() throws {
        let baseCommand = "xcodebuild test -scheme nnex -quiet"
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary", ""], testCommand: .custom(baseCommand))
        
        try sut.discardableBuild()
        
        let testCommand = shell.executedCommands.first { $0.contains("xcodebuild") }
        #expect(testCommand?.contains("-quiet") == true)
        #expect(testCommand?.contains("-allowProvisioningUpdates") == true)
        // Should only contain -quiet once
        let quietCount = testCommand?.components(separatedBy: "-quiet").count ?? 0
        #expect(quietCount == 2) // Original string + 1 split = 2 components
    }

    @Test("Custom command with both flags remains unchanged")
    func customCommandWithBothFlags() throws {
        let baseCommand = "xcodebuild test -scheme nnex -quiet -allowProvisioningUpdates"
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary", ""], testCommand: .custom(baseCommand))
        
        try sut.discardableBuild()
        
        let testCommand = shell.executedCommands.first { $0.contains("xcodebuild") }
        // Should contain both flags but not be duplicated
        let quietCount = testCommand?.components(separatedBy: "-quiet").count ?? 0
        let allowProvisioningCount = testCommand?.components(separatedBy: "-allowProvisioningUpdates").count ?? 0
        #expect(quietCount == 2) // Original string + 1 split = 2 components
        #expect(allowProvisioningCount == 2) // Original string + 1 split = 2 components
    }

    @Test("Custom command with flags in different positions avoids duplication")
    func customCommandWithFlagsInDifferentPositions() throws {
        let baseCommand = "xcodebuild -quiet test -scheme nnex -allowProvisioningUpdates"
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary", ""], testCommand: .custom(baseCommand))
        
        try sut.discardableBuild()
        
        let testCommand = shell.executedCommands.first { $0.contains("xcodebuild") }
        let quietCount = testCommand?.components(separatedBy: "-quiet").count ?? 0
        let allowProvisioningCount = testCommand?.components(separatedBy: "-allowProvisioningUpdates").count ?? 0
        #expect(quietCount == 2) // Should only appear once
        #expect(allowProvisioningCount == 2) // Should only appear once
    }

    @Test("Default command does not get custom flags added")
    func defaultCommandUnchanged() throws {
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary", ""], testCommand: .defaultCommand)
        
        try sut.discardableBuild()
        
        let testCommand = shell.executedCommands.first { $0.contains("swift test") }
        #expect(testCommand?.contains("swift test --package-path \(projectPath)") == true)
        #expect(testCommand?.contains("-quiet") == false)
        #expect(testCommand?.contains("-allowProvisioningUpdates") == false)
    }
    
    @Test("Includes cleaning by default")
    func includesCleaning() throws {
        // Need results for: clean, build arm64, build x86_64, shasum arm, shasum intel
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"])
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains("swift package clean --package-path \(projectPath)") })
    }
    
    @Test("Skips cleaning when indicated")
    func skipsCleaning() throws {
        // Need results for: build arm64, build x86_64, shasum arm, shasum intel (no clean)
        let armSha256 = "arm123def456"
        let intelSha256 = "intel123def456"
        let (sut, shell) = makeSUT(runResults: ["", "", "\(armSha256)  /path/to/binary", "\(intelSha256)  /path/to/binary"], skipClean: true)
        
        try sut.discardableBuild()
        
        #expect(!shell.executedCommands.contains { $0.contains("swift package clean --package-path \(projectPath)") })
    }
}


// MARK: - Error Validation
extension ProjectBuilderTests {
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
    func discardableBuild() throws -> BinaryOutput {
        return try build()
    }
}

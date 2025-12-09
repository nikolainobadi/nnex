//
//  ProjectBuilderTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Testing
import NnShellTesting
@testable import NnexKit

struct ProjectBuilderTests {
    private let projectName = "TestProject"
    private let projectPath = "/path/to/project"
    private let extraArgs = ["extraArg"]
    private let customTestCommand = "swift test --filter SomeTests"
}

// MARK: - Success Tests
extension ProjectBuilderTests {
    @Test("Successfully builds a universal binary")
    func buildUniversalBinary() throws {
        let shellResults = [
            "", // clean
            "", // build arm64
            ""  // build x86_64
        ]
        
        let sut = makeSUT(runResults: shellResults).sut
        let result = try sut.discardableBuild()
        
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
    
    @Test("Successfully builds an single binary", arguments: [BuildType.arm64, BuildType.x86_64])
    func buildSingleBinary(buildType: BuildType) throws {
        let sut = makeSUT(buildType: buildType, runResults: ["", ""]).sut
        let result = try sut.discardableBuild()
        
        switch result {
        case .single(let info):
            #expect(info.path.contains(projectPath))
            #expect(info.path.contains("\(buildType.rawValue)-apple-macosx"))
            #expect(info.path.contains(projectName))
        case .multiple:
            Issue.record("Expected .single BinaryOutput but found .multiple")
        }
    }
    
    @Test("Successfully passes extra build arguments")
    func buildWithExtraArgs() throws {
        // Need results for: clean, build arm64, build x86_64, test
        let (sut, shell) = makeSUT(runResults: ["", "", "", ""])
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
        // Need results for: clean, build arm64, build x86_64, test
        let (sut, shell) = makeSUT(runResults: ["", "", "", ""], testCommand: .defaultCommand)
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains("swift test") })
    }

    @Test("Runs custom test command after build")
    func runsCustomTestCommand() throws {
        // Need results for: clean, build arm64, build x86_64, test
        let (sut, shell) = makeSUT(runResults: ["", "", "", ""], testCommand: .custom(customTestCommand))
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains(customTestCommand) })
    }

    @Test("Skips running tests if no test command is provided")
    func skipsRunningTests() throws {
        // Need results for: clean, build arm64, build x86_64
        let (sut, shell) = makeSUT(runResults: ["", "", ""], testCommand: nil)
        
        try sut.discardableBuild()
        
        #expect(!shell.executedCommands.contains { $0.contains("swift test") })
        #expect(!shell.executedCommands.contains { $0.contains(customTestCommand) })
    }

    @Test("Custom command without flags gets required flags added")
    func customCommandWithoutFlags() throws {
        let baseCommand = "xcodebuild test -scheme nnex"
        let (sut, shell) = makeSUT(runResults: ["", "", "", ""], testCommand: .custom(baseCommand))
        
        try sut.discardableBuild()
        
        let testCommand = shell.executedCommands.first { $0.contains("xcodebuild") }
        #expect(testCommand?.contains("-quiet") == true)
        #expect(testCommand?.contains("-allowProvisioningUpdates") == true)
        #expect(testCommand?.contains(baseCommand) == true)
    }

    @Test("Custom command with one flag gets missing flag added")
    func customCommandWithOneFlag() throws {
        let baseCommand = "xcodebuild test -scheme nnex -quiet"
        let (sut, shell) = makeSUT(runResults: ["", "", "", ""], testCommand: .custom(baseCommand))
        
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
        let (sut, shell) = makeSUT(runResults: ["", "", "", ""], testCommand: .custom(baseCommand))
        
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
        let (sut, shell) = makeSUT(runResults: ["", "", "", ""], testCommand: .custom(baseCommand))
        
        try sut.discardableBuild()
        
        let testCommand = shell.executedCommands.first { $0.contains("xcodebuild") }
        let quietCount = testCommand?.components(separatedBy: "-quiet").count ?? 0
        let allowProvisioningCount = testCommand?.components(separatedBy: "-allowProvisioningUpdates").count ?? 0
        #expect(quietCount == 2) // Should only appear once
        #expect(allowProvisioningCount == 2) // Should only appear once
    }

    @Test("Default command does not get custom flags added")
    func defaultCommandUnchanged() throws {
        let (sut, shell) = makeSUT(runResults: ["", "", "", ""], testCommand: .defaultCommand)
        
        try sut.discardableBuild()
        
        let testCommand = shell.executedCommands.first { $0.contains("swift test") }
        #expect(testCommand?.contains("swift test --package-path \(projectPath)") == true)
        #expect(testCommand?.contains("-quiet") == false)
        #expect(testCommand?.contains("-allowProvisioningUpdates") == false)
    }
    
    @Test("Includes cleaning by default")
    func includesCleaning() throws {
        // Need results for: clean, build arm64, build x86_64
        let (sut, shell) = makeSUT(runResults: ["", "", ""])
        
        try sut.discardableBuild()
        
        #expect(shell.executedCommands.contains { $0.contains("swift package clean --package-path \(projectPath)") })
    }
    
    @Test("Skips cleaning when indicated")
    func skipsCleaning() throws {
        // Need results for: build arm64, build x86_64 (no clean)
        let (sut, shell) = makeSUT(runResults: ["", ""], skipClean: true)
        
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
    
//    @Test("Throws TestFailureError when tests fail")
//    func testFailureThrowsTestFailureError() throws {
//        // Create a custom mock shell that succeeds for build commands but throws ShellError for test commands
//        let shell = TestFailureMockShell()
//        
//        let config = BuildConfig(
//            projectName: projectName,
//            projectPath: projectPath,
//            buildType: .arm64,
//            extraBuildArgs: [],
//            skipClean: false,
//            testCommand: .defaultCommand
//        )
//        
//        let sut = ProjectBuilder(shell: shell, config: config)
//        
//        var caughtError: TestFailureError?
//        do {
//            try sut.discardableBuild()
//        } catch let error as TestFailureError {
//            caughtError = error
//        } catch {
//            Issue.record("Expected TestFailureError but got \(type(of: error)): \(error)")
//        }
//        
//        #expect(caughtError != nil, "Should have caught a TestFailureError")
//        #expect(caughtError?.command.contains("swift test") == true, "Error should contain the test command")
//        #expect(caughtError?.output.contains("Test failed") == true, "Error should contain test output")
//        #expect(caughtError?.errorDescription?.contains("Tests failed when running") == true, "Error should have descriptive message")
//    }
}


// MARK: - SUT
private extension ProjectBuilderTests {
    func makeSUT(buildType: BuildType = .universal, runResults: [String] = [], throwShellError: Bool = false, testCommand: TestCommand? = nil, skipClean: Bool = false) -> (sut: ProjectBuilder, shell: MockShell) {
        let shell = MockShell(results: runResults, shouldThrowErrorOnFinal: throwShellError)
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

//
//  PublishTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit
import Testing
import NnShellKit
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
final class PublishTests {
    private let tapFolder: Folder
    private let projectFolder: Folder
    private let tapName = "testTap"
    private let assetURL = "assetURL"
    private let sha256 = "abc123def456"  // Just the hash value
    private let sha256Output = "abc123def456  /path/to/file"  // Shasum command output format
    private let versionNumber = "v1.0.0"
    private let projectName = "testProject"
    private let releaseNotes = "release notes"
    private let commitMessage = "commit message"
    
    private var formulaFileName: String {
        return "\(projectName).rb"
    }
    
    init() throws {
        let tempFolder = Folder.temporary
        self.projectFolder = try tempFolder.createSubfolder(named: projectName)
        self.tapFolder = try tempFolder.createSubfolder(named: "homebrew-\(tapName)")
    }
    
    deinit {
        deleteFolderContents(tapFolder)
        deleteFolderContents(projectFolder)
    }
}


// MARK: - Unit Tests
extension PublishTests {
    @Test("Cannot publish if 'gh' is not installed")
    func publishFailsWithNoGHCLI() throws {
        let gitHandler = MockGitHandler(ghIsInstalled: false)
        let factory = MockContextFactory(runResults: ["", "", "", sha256Output, sha256Output], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        
        #expect(throws: NnexError.missingGitHubCLI) {
            try runCommand(factory, version: .version(versionNumber), message: commitMessage)
        }
        
        let tapFolder = try #require(try Folder(path: tapFolder.path))
        
        #expect(gitHandler.message == nil)
        #expect(gitHandler.releaseNoteInfo == nil)
        #expect(tapFolder.containsFile(named: formulaFileName) == false)
    }
    
    @Test("Creates formula file when publishing")
    func publishCommand() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 10) // Add extra results in case more commands are called
        let factory = MockContextFactory(
            runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL) + extraResults,
            gitHandler: gitHandler
        )
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes, buildType: .universal)
        
        let formulaFileContents = try #require(try Folder(path: tapFolder.path).file(named: formulaFileName).readAsString())
        
        #expect(formulaFileContents.contains(projectName.capitalized))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
    }
    
    @Test("Creates formula file with sanitized class name when project has dashes")
    func publishCommandWithDashesInName() throws {
        let projectWithDashes = "test-project-with-dashes"
        let expectedClassName = "TestProjectWithDashes"
        let tempFolder = Folder.temporary
        let projectFolderWithDashes = try tempFolder.createSubfolder(named: projectWithDashes)
        let formulaFileNameWithDashes = "\(projectWithDashes).rb"
        
        defer {
            deleteFolderContents(projectFolderWithDashes)
        }
        
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 10) // Add extra results in case more commands are called
        let factory = MockContextFactory(runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL) + extraResults, gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory, projectName: projectWithDashes, projectFolder: projectFolderWithDashes)
        
        let args = ["brew", "publish", "-p", projectFolderWithDashes.path, "-v", versionNumber, "-m", commitMessage, "-n", releaseNotes]
        try Nnex.testRun(contextFactory: factory, args: args)
        
        let formulaFileContents = try #require(try Folder(path: tapFolder.path).file(named: formulaFileNameWithDashes).readAsString())
        
        #expect(formulaFileContents.contains("class \(expectedClassName)"))
        #expect(!formulaFileContents.contains("class \(projectWithDashes)"))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
    }
}


// MARK: - Passing Info to Args
extension PublishTests {
    @Test("Commits changes when commit message is included in args")
    func commitsChanges() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 10)
        let factory = MockContextFactory(runResults: ["", "", "", sha256Output, sha256Output] + extraResults, gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(gitHandler.message == commitMessage)
    }
    
    @Test("Automatically updates localProjectPath for formula if it doesn't match project folder path")
    func updatesFormulaLocalPath() throws {
        let staleLocalPath = "~/Desktop/stale"
        let extraResults = Array(repeating: sha256Output, count: 10)
        let factory = MockContextFactory(runResults: ["", "", "", sha256Output, sha256Output] + extraResults)
        let context = try factory.makeContext()
        
        try createTestTapAndFormula(factory: factory, formulaPath: staleLocalPath)
        
        let staleFormula = try #require(try context.loadFormulas().first)
        
        #expect(staleFormula.localProjectPath == staleLocalPath)
        
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        let allFormulas = try #require(try context.loadFormulas())
        
        #expect(allFormulas.count == 1)
        
        let updatedFormula = try #require(allFormulas.first)
        
        #expect(updatedFormula.localProjectPath == projectFolder.path)
    }
    
    @Test("Uploads with inline release notes when included in args")
    func uploadsDirectReleaseNotes() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 10)
        let factory = MockContextFactory(runResults: ["", "", "", sha256Output, sha256Output] + extraResults, gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        let releaseNoteInfo = try #require(gitHandler.releaseNoteInfo)
        
        #expect(releaseNoteInfo.isFromFile == false)
        #expect(releaseNoteInfo.content == releaseNotes)
    }
    
    @Test("Uploads release notes from file when included in args")
    func uploadsReleaseNotesFromFile() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 10)
        let factory = MockContextFactory(runResults: ["", "", "", sha256Output, sha256Output] + extraResults, gitHandler: gitHandler)
        let releaseNoteFile = try #require(try projectFolder.createFile(named: "TestReleaseNotes.md"))
        let filePath = releaseNoteFile.path
        
        try releaseNoteFile.write(releaseNotes)
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notesFile: filePath)
        
        let releaseNoteInfo = try #require(gitHandler.releaseNoteInfo)
        
        #expect(releaseNoteInfo.isFromFile)
        #expect(releaseNoteInfo.content == filePath)
    }
    
    @Test("Does not include tests when none exist")
    func doesNotIncludeTests() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 10)
        let shell = MockShell(results: ["", "", "", sha256Output, sha256Output] + extraResults)
        let factory = MockContextFactory(runResults: ["", "", "", sha256Output, sha256Output] + extraResults, gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(!shell.executedCommands.contains(where: { $0.contains("swift test") }))
    }
    
    @Test("Runs tests when formula includes default test command", .disabled())
    func runsTestsWithDefaultCommand() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 50) // Increase to ensure enough results
        let testResults = makePublishMockResults(sha256: sha256, assetURL: assetURL, includeTestCommand: true) + extraResults
        let shell = MockShell(results: testResults)
        let factory = MockContextFactory(runResults: testResults, gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .defaultCommand)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(shell.executedCommands.contains { $0.contains("swift test") })
    }
    
    @Test("Runs tests when formula includes custom test command", .disabled())
    func runsTestsWithCustomCommand() throws {
        let testCommand = "xcodebuild test -scheme testScheme -destination 'platform=macOS'"
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 50) // Increase to ensure enough results
        let testResults = makePublishMockResults(sha256: sha256, assetURL: assetURL, includeTestCommand: true) + extraResults
        let shell = MockShell(results: testResults)
        let factory = MockContextFactory(runResults: testResults, gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .custom(testCommand))
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(shell.executedCommands.contains { $0.contains(testCommand) })
    }
    
    @Test("Skips tests when indicated in arg even when formula contains test command", arguments: [TestCommand.defaultCommand, TestCommand.custom("some command"), nil])
    func skipsTests(testCommand: TestCommand?) throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 10)
        let testResults = ["", "", "", sha256Output, sha256Output] + extraResults
        let shell = MockShell(results: testResults)
        let factory = MockContextFactory(runResults: testResults, gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: testCommand)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes, skipTests: true)
        
        if let testCommand {
            switch testCommand {
            case .custom(let command):
                #expect(!shell.executedCommands.contains { $0.contains(command) })
            default:
                break
            }
        }
        
        #expect(!shell.executedCommands.contains { $0.contains("swift test") })
    }
    
    @Test("Fails to publish when tests fail")
    func failsToPublishWhenTestsFail() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let extraResults = Array(repeating: sha256Output, count: 10)
        let testResults = ["", "", "", sha256Output, sha256Output] + extraResults
        let shell = MockShell(results: testResults, shouldThrowError: true)
        let factory = MockContextFactory(runResults: testResults, gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .defaultCommand)
        
        #expect(throws: (any Error).self) {
            try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        }
        
        withKnownIssue("Determining which shell command fails is currently unreliable") {
            #expect(shell.executedCommands.contains { $0.contains("swift test") })
        }
    }
}


// MARK: - Input Provided from User
extension PublishTests {
    @Test("Publishes a binary to Homebrew and verifies the formula file when infomation must be input and file path for release notes is input.")
    func publishCommandWithInputsAndFilePathReleaseNotes() throws {
        let releaseNoteFile = try #require(try projectFolder.createFile(named: "TestReleaseNotes.md"))
        let filePath = releaseNoteFile.path
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let trashHandler = MockTrashHandler()
        let inputs = [versionNumber, filePath, commitMessage]
        let extraResults = Array(repeating: sha256Output, count: 10)
        let factory = MockContextFactory(runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL) + extraResults, selectedItemIndex: 1, inputResponses: inputs, permissionResponses: [true, true], gitHandler: gitHandler, trashHandler: trashHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory)
        
        let releaseNoteInfo = try #require(gitHandler.releaseNoteInfo)
        let formulaFileContents = try #require(try Folder(path: tapFolder.path).file(named: formulaFileName).readAsString())
        
        #expect(formulaFileContents.contains(projectName.capitalized))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
        #expect(gitHandler.message == commitMessage)
        #expect(releaseNoteInfo.isFromFile)
        #expect(releaseNoteInfo.content == filePath)
        #expect(trashHandler.lastMovedPath == filePath)
    }
    
    @Test("Does not delete release notes file when user declines deletion prompt")
    func doesNotDeleteReleaseNotesWhenUserDeclines() throws {
        let releaseNoteFile = try #require(try projectFolder.createFile(named: "TestReleaseNotes.md"))
        let filePath = releaseNoteFile.path
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let trashHandler = MockTrashHandler()
        let inputs = [versionNumber, filePath, commitMessage]
        let extraResults = Array(repeating: sha256Output, count: 10)
        let factory = MockContextFactory(runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL) + extraResults, selectedItemIndex: 1, inputResponses: inputs, permissionResponses: [false, true], gitHandler: gitHandler, trashHandler: trashHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory)
        
        #expect(trashHandler.lastMovedPath == nil)
    }
}


// MARK: - Run Command
private extension PublishTests {
    func runCommand(_ factory: MockContextFactory, version: ReleaseVersionInfo? = nil, message: String? = nil, notes: String? = nil, notesFile: String? = nil, skipTests: Bool = false, buildType: BuildType? = nil) throws {
        var args = ["brew", "publish", "-p", projectFolder.path]
        
        if let version {
            args.append(contentsOf: ["-v", version.arg])
        }
        
        if let message {
            args.append(contentsOf: ["-m", message])
        }
        
        if let notes {
            args.append(contentsOf: ["-n", notes])
        }
        
        if let notesFile {
            args.append(contentsOf: ["-F", notesFile])
        }
        
        if skipTests {
            args.append("--skip-tests")
        }
        
        if let buildType {
            args.append(contentsOf: ["-b", buildType.rawValue])
        }
        
        try Nnex.testRun(contextFactory: factory, args: args)
    }
}


// MARK: - Helpers
private extension PublishTests {
    func createTestTapAndFormula(factory: MockContextFactory, formulaPath: String? = nil, testCommand: TestCommand? = nil, extraBuildArgs: [String] = [], projectName: String? = nil, projectFolder: Folder? = nil) throws {
        let context = try factory.makeContext()
        let tap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        let effectiveProjectName = projectName ?? self.projectName
        let effectiveProjectFolder = projectFolder ?? self.projectFolder
        let formula = SwiftDataFormula(name: effectiveProjectName, details: "details", homepage: "homepage", license: "MIT", localProjectPath: formulaPath ?? effectiveProjectFolder.path, uploadType: .binary, testCommand: testCommand, extraBuildArgs: extraBuildArgs)
        
        try context.saveNewTap(tap, formulas: [formula])
    }
    
    /// Creates mock results for publish workflows that expect SHA256 and asset URL
    /// - Parameters:
    ///   - sha256: The SHA256 value to return for shasum command
    ///   - assetURL: The asset URL to return for GitHub release command
    ///   - includeTestCommand: Whether to include an extra result for test command execution
    /// - Returns: Array of mock results positioned correctly for publish workflow
    func makePublishMockResults(sha256: String, assetURL: String, includeTestCommand: Bool = false) -> [String] {
        // New simplified build workflow:
        // 1. Clean project (if not skipped)
        // 2. Build for arm64
        // 3. Build for x86_64 (for universal builds)
        // 4. Get SHA256 for arm64
        // 5. Get SHA256 for x86_64 (for universal builds)
        // 6. Run tests (if included)
        
        var results = [
            "",       // 1. Clean project
            "",       // 2. Build arm64
            "",       // 3. Build x86_64
            sha256Output,   // 4. SHA256 for arm64 (shasum output format)
            sha256Output,   // 5. SHA256 for x86_64 (shasum output format)
        ]
        
        if includeTestCommand {
            results.append("") // 6. Test command execution
        }
        
        return results
    }
}


// MARK: - Extension Dependencies
fileprivate extension ReleaseVersionInfo {
    var arg: String {
        switch self {
        case .version(let number):
            return number
        case .increment(let part):
            return part.rawValue
        }
    }
}

//
//  PublishTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit
import Testing
import NnShellTesting
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
final class PublishTests: BasePublishTestSuite {
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
        try super.init(tapName: tapName, projectName: projectName)
    }
}


// MARK: - Unit Tests
extension PublishTests {
    @Test("Cannot publish if 'gh' is not installed")
    func publishFailsWithNoGHCLI() throws {
        let gitHandler = MockGitHandler(ghIsInstalled: false)
        let shell = createMockShell()
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory)
        
        do {
            try runCommand(factory, version: .version(versionNumber), message: commitMessage)
            Issue.record("Expected an error to be thrown")
        } catch { }
        
        let tapFolder = try Folder(path: tapFolder.path)
        
        #expect(gitHandler.message == nil)
        #expect(gitHandler.releaseNoteInfo == nil)
        #expect(tapFolder.containsFile(named: formulaFileName) == false)
    }
    
    @Test("Creates formula file when publishing")
    func publishCommand() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let shell = createMockShell()
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes, buildType: .universal)
        
        let formulaFileContents = try getFormulaFolder().file(named: formulaFileName).readAsString()
        
        #expect(formulaFileContents.contains(projectName.capitalized))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
    }
    
    @Test("Creates formula file with sanitized class name when project has dashes")
    func publishCommandWithDashesInName() throws {
        let projectWithDashes = "test-project-with-dashes"
        let expectedClassName = "TestProjectWithDashes"
        let projectFolderWithDashes = try tempFolder.createSubfolder(named: projectWithDashes)
        let formulaFileNameWithDashes = "\(projectWithDashes).rb"
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let shell = createMockShell(projectName: projectWithDashes, projectPath: projectFolderWithDashes.path)
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, projectName: projectWithDashes, projectFolder: projectFolderWithDashes)
        
        let args = ["brew", "publish", "-p", projectFolderWithDashes.path, "-v", versionNumber, "-m", commitMessage, "-n", releaseNotes]
        try Nnex.testRun(contextFactory: factory, args: args)
        
        let formulaFileContents = try getFormulaFolder().file(named: formulaFileNameWithDashes).readAsString()
        
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
        let shell = createMockShell()
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(gitHandler.message == commitMessage)
    }
    
    @Test("Automatically updates localProjectPath for formula if it doesn't match project folder path")
    func updatesFormulaLocalPath() throws {
        let staleLocalPath = "~/Desktop/stale"
        let shell = createMockShell()
        let factory = MockContextFactory(shell: shell)
        let context = try factory.makeContext()
        
        try createTestTapAndFormula(factory: factory, formulaPath: staleLocalPath)
        
        let staleFormula = try #require(try context.loadFormulas().first)
        
        #expect(staleFormula.localProjectPath == staleLocalPath)
        
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        let allFormulas = try context.loadFormulas()
        
        #expect(allFormulas.count == 1)
        
        let updatedFormula = try #require(allFormulas.first)
        
        #expect(updatedFormula.localProjectPath == projectFolder.path)
    }
    
    @Test("Uploads with inline release notes when included in args")
    func uploadsDirectReleaseNotes() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let shell = createMockShell()
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        let releaseNoteInfo = try #require(gitHandler.releaseNoteInfo)
        
        #expect(releaseNoteInfo.isFromFile == false)
        #expect(releaseNoteInfo.content == releaseNotes)
    }
    
    @Test("Uploads release notes from file when included in args")
    func uploadsReleaseNotesFromFile() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let shell = createMockShell()
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        let releaseNoteFile = try projectFolder.createFile(named: "TestReleaseNotes.md")
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
        let shell = createMockShell(includeTestCommand: false)
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(!shell.executedCommands.contains(where: { $0.contains("swift test") }))
    }
    
    @Test("Runs tests when formula includes default test command")
    func runsTestsWithDefaultCommand() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let shell = createMockShell(includeTestCommand: true)
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .defaultCommand)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(shell.executedCommands.contains { $0.contains("swift test") })
    }
    
    @Test("Runs tests when formula includes custom test command")
    func runsTestsWithCustomCommand() throws {
        let testCommand = "xcodebuild test -scheme testScheme -destination 'platform=macOS'"
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let shell = createMockShell(includeTestCommand: true)
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .custom(testCommand))
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(shell.executedCommands.contains { $0.contains(testCommand) })
    }
    
    @Test("Skips tests when indicated in arg even when formula contains test command", arguments: [TestCommand.defaultCommand, TestCommand.custom("some command"), nil])
    func skipsTests(testCommand: TestCommand?) throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let shell = createMockShell(includeTestCommand: false)
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
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
        let shell = createMockShell(includeTestCommand: false, shouldThrowError: true)
        let factory = MockContextFactory(gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .defaultCommand)
        
        do {
            try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
            Issue.record("Expected an error to be thrown")
        } catch { }
    }
}


// MARK: - Input Provided from User
extension PublishTests {
    @Test("Publishes a binary to Homebrew and verifies the formula file when infomation must be input and file path for release notes is input.") 
    func publishCommandWithInputsAndFilePathReleaseNotes() throws {
        let releaseNoteFile = try projectFolder.createFile(named: "TestReleaseNotes.md")
        let filePath = releaseNoteFile.path
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let trashHandler = MockTrashHandler()
        let inputs = [versionNumber, filePath, commitMessage]
        let shell = createMockShell()
        let factory = MockContextFactory(selectedItemIndex: 2, inputResponses: inputs, permissionResponses: [true, true], gitHandler: gitHandler, shell: shell, trashHandler: trashHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory)
        
        let releaseNoteInfo = try #require(gitHandler.releaseNoteInfo)
        let formulaFileContents = try getFormulaFolder().file(named: formulaFileName).readAsString()
        
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
        let releaseNoteFile = try projectFolder.createFile(named: "TestReleaseNotes.md")
        let filePath = releaseNoteFile.path
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let trashHandler = MockTrashHandler()
        let inputs = [versionNumber, filePath, commitMessage]
        let shell = createMockShell()
        let factory = MockContextFactory(selectedItemIndex: 2, inputResponses: inputs, permissionResponses: [false, true], gitHandler: gitHandler, shell: shell, trashHandler: trashHandler)
        
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
    func getFormulaFolder() throws -> Folder {
        return try tapFolder.subfolder(named: "Formula")
    }
    
    func createMockShell(projectName: String? = nil, projectPath: String? = nil, includeTestCommand: Bool = false, shouldThrowError: Bool = false) -> MockShell {
        if shouldThrowError {
            return .init(shouldThrowErrorOnFinal: true)
        }
        
        let projectPath = projectPath ?? projectFolder.path
        let commandResults: [String: String] = [
            "shasum -a 256 \"\(projectPath).build/arm64-apple-macosx/release/\(projectName ?? self.projectName)-arm64.tar.gz\"": sha256Output,
            "shasum -a 256 \"\(projectPath).build/x86_64-apple-macosx/release/\(projectName ?? self.projectName)-x86_64.tar.gz\"": sha256Output
        ]
        
        return .init(commands: commandResults.map({ .init(command: $0, output: $1) }))
    }
    
    func createTestTapAndFormula(factory: MockContextFactory, formulaPath: String? = nil, testCommand: TestCommand? = nil, extraBuildArgs: [String] = [], projectName: String? = nil, projectFolder: Folder? = nil) throws {
        let context = try factory.makeContext()
        let tap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        let effectiveProjectName = projectName ?? self.projectName
        let effectiveProjectFolder = projectFolder ?? self.projectFolder
        let formula = SwiftDataFormula(name: effectiveProjectName, details: "details", homepage: "homepage", license: "MIT", localProjectPath: formulaPath ?? effectiveProjectFolder.path, uploadType: .binary, testCommand: testCommand, extraBuildArgs: extraBuildArgs)
        
        try context.saveNewTap(tap, formulas: [formula])
    }
}


// MARK: - Extension Dependencies
private extension ReleaseVersionInfo {
    var arg: String {
        switch self {
        case .version(let number):
            return number
        case .increment(let part):
            return part.rawValue
        }
    }
}

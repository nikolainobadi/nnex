//
//  PublishTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit
import Testing
import NnexSharedTestHelpers
@testable import nnex
@preconcurrency import Files

@MainActor // needs to be MainActor to ensure proper interactions with SwiftData
final class PublishTests {
    private let tapFolder: Folder
    private let projectFolder: Folder
    private let tapName = "testTap"
    private let assetURL = "assetURL"
    private let sha256 = "abc123def456"
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
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler)
        
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
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        let formulaFileContents = try #require(try Folder(path: tapFolder.path).file(named: formulaFileName).readAsString())
        
        #expect(formulaFileContents.contains(projectName))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
    }
}


// MARK: - Passing Info to Args
extension PublishTests {
    @Test("Commits changes when commit message is included in args")
    func commitsChanges() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(gitHandler.message == commitMessage)
    }
    
    @Test("Uploads with inline release notes when included in args")
    func uploadsDirectReleaseNotes() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        let releaseNoteInfo = try #require(gitHandler.releaseNoteInfo)
        
        #expect(releaseNoteInfo.isFromFile == false)
        #expect(releaseNoteInfo.content == releaseNotes)
    }
    
    @Test("Uploads release notes from file when included in args")
    func uploadsReleaseNotesFromFile() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler)
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
        let shell = MockShell()
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(!shell.printedCommands.contains(where: { $0.contains("swift test") }))
    }
    
    @Test("Runs tests when formula includes default test command")
    func runsTestsWithDefaultCommand() throws {
        let shell = MockShell()
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .defaultCommand)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(shell.printedCommands.contains { $0.contains("swift test") })
    }
    
    @Test("Runs tests when formula includes custom test command")
    func runsTestsWithCustomCommand() throws {
        let shell = MockShell()
        let testCommand = "xcodebuild test -scheme testScheme -destination 'platform=macOS'"
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .custom(testCommand))
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(shell.printedCommands.contains { $0.contains(testCommand) })
    }
    
    @Test("Skips tests when indicated in arg even when formula contains test command", arguments: [TestCommand.defaultCommand, TestCommand.custom("some command"), nil])
    func skipsTests(testCommand: TestCommand?) throws {
        let shell = MockShell()
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: testCommand)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes, skipTests: true)
        
        if let testCommand {
            switch testCommand {
            case .custom(let command):
                #expect(!shell.printedCommands.contains { $0.contains(command) })
            default:
                break
            }
        }
        
        #expect(!shell.printedCommands.contains { $0.contains("swift test") })
    }
    
    @Test("Fails to publish when tests fail")
    func failsToPublishWhenTestsFail() throws {
        let shell = MockShell(shouldThrowError: true)
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .defaultCommand)
        
        #expect(throws: (any Error).self) {
            try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        }
        
        withKnownIssue("Determining which shell command fails is currently unreliable") {
            #expect(shell.printedCommands.contains { $0.contains("swift test") })
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
        let inputs = [versionNumber, filePath, commitMessage]
        let factory = MockContextFactory(runResults: [sha256, assetURL], selectedItemIndex: 1, inputResponses: inputs, permissionResponses: [true], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory)
        
        let releaseNoteInfo = try #require(gitHandler.releaseNoteInfo)
        let formulaFileContents = try #require(try Folder(path: tapFolder.path).file(named: formulaFileName).readAsString())
        
        #expect(formulaFileContents.contains(projectName))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
        #expect(gitHandler.message == commitMessage)
        #expect(releaseNoteInfo.isFromFile)
        #expect(releaseNoteInfo.content == filePath)
    }
}


// MARK: - Run Command
private extension PublishTests {
    func runCommand(_ factory: MockContextFactory, version: ReleaseVersionInfo? = nil, message: String? = nil, notes: String? = nil, notesFile: String? = nil, skipTests: Bool = false) throws {
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
        
        try Nnex.testRun(contextFactory: factory, args: args)
    }
}


// MARK: - Helpers
private extension PublishTests {
    func createTestTapAndFormula(factory: MockContextFactory, testCommand: TestCommand? = nil, extraBuildArgs: [String] = []) throws {
        let context = try factory.makeContext()
        let tap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        let formula = SwiftDataFormula(name: projectName, details: "details", homepage: "homepage", license: "MIT", localProjectPath: projectFolder.path, uploadType: .binary, testCommand: testCommand, extraBuildArgs: extraBuildArgs)
        
        try context.saveNewTap(tap, formulas: [formula])
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

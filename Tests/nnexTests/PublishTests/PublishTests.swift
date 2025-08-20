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
        let factory = MockContextFactory(runResults: ["", sha256, assetURL], gitHandler: gitHandler)
        
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
        let factory = MockContextFactory(
            runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL),
            gitHandler: gitHandler
        )
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        let formulaFileContents = try #require(try Folder(path: tapFolder.path).file(named: formulaFileName).readAsString())
        
        #expect(formulaFileContents.contains(projectName))
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
        let factory = MockContextFactory(runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL), gitHandler: gitHandler)
        
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
        let factory = MockContextFactory(runResults: ["", sha256, assetURL], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(gitHandler.message == commitMessage)
    }
    
    @Test("Automatically updates localProjectPath for formula if it doesn't match project folder path")
    func updatesFormulaLocalPath() throws {
        let staleLocalPath = "~/Desktop/stale"
        let factory = MockContextFactory(runResults: ["", sha256, assetURL])
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
        let factory = MockContextFactory(runResults: ["", sha256, assetURL], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        let releaseNoteInfo = try #require(gitHandler.releaseNoteInfo)
        
        #expect(releaseNoteInfo.isFromFile == false)
        #expect(releaseNoteInfo.content == releaseNotes)
    }
    
    @Test("Uploads release notes from file when included in args")
    func uploadsReleaseNotesFromFile() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: ["", sha256, assetURL], gitHandler: gitHandler)
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
        let factory = MockContextFactory(runResults: ["", sha256, assetURL], gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(!shell.executedCommands.contains(where: { $0.contains("swift test") }))
    }
    
    @Test("Runs tests when formula includes default test command")
    func runsTestsWithDefaultCommand() throws {
        let shell = MockShell()
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL, includeTestCommand: true), gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .defaultCommand)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(shell.executedCommands.contains { $0.contains("swift test") })
    }
    
    @Test("Runs tests when formula includes custom test command")
    func runsTestsWithCustomCommand() throws {
        let shell = MockShell()
        let testCommand = "xcodebuild test -scheme testScheme -destination 'platform=macOS'"
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL, includeTestCommand: true), gitHandler: gitHandler, shell: shell)
        
        try createTestTapAndFormula(factory: factory, testCommand: .custom(testCommand))
        try runCommand(factory, version: .version(versionNumber), message: commitMessage, notes: releaseNotes)
        
        #expect(shell.executedCommands.contains { $0.contains(testCommand) })
    }
    
    @Test("Skips tests when indicated in arg even when formula contains test command", arguments: [TestCommand.defaultCommand, TestCommand.custom("some command"), nil])
    func skipsTests(testCommand: TestCommand?) throws {
        let shell = MockShell()
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: ["", sha256, assetURL], gitHandler: gitHandler, shell: shell)
        
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
        let shell = MockShell(shouldThrowError: true)
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: ["", sha256, assetURL], gitHandler: gitHandler, shell: shell)
        
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
    // TODO: - need to update test to work with new 'delete releaseNotes' feature
    @Test("Publishes a binary to Homebrew and verifies the formula file when infomation must be input and file path for release notes is input.", .disabled())
    func publishCommandWithInputsAndFilePathReleaseNotes() throws {
        let releaseNoteFile = try #require(try projectFolder.createFile(named: "TestReleaseNotes.md"))
        let filePath = releaseNoteFile.path
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let inputs = [versionNumber, filePath, commitMessage]
        let factory = MockContextFactory(runResults: makePublishMockResults(sha256: sha256, assetURL: assetURL), selectedItemIndex: 1, inputResponses: inputs, permissionResponses: [true], gitHandler: gitHandler)
        
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
        var results = [
            "",       // 1. Clean project
            "",       // 2. Build arm64
            "",       // 3. Build x86_64  
            "",       // 4. Create universal binary folder
            "",       // 5. Combine architectures (lipo)
            "",       // 6. Strip symbols
            "",       // 7. Create GitHub release
            sha256,   // 8. Calculate SHA256 (shasum)
            assetURL  // 9. Get latest release asset URL
        ]
        
        if includeTestCommand {
            results.append("") // 10. Test command execution
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

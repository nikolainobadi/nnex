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
        #expect(tapFolder.containsFile(named: formulaFileName) == false)
    }
    
    // TODO: - 
    @Test("Publishes a binary to Homebrew and verifies the formula file when passing in path, version, and message", .disabled())
    func testPublishCommand() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let factory = MockContextFactory(runResults: [sha256, assetURL], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory, version: .version(versionNumber), message: commitMessage)
        
        let formulaFileContents = try #require(try Folder(path: tapFolder.path).file(named: formulaFileName).readAsString())
        
        #expect(formulaFileContents.contains(projectName))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
        #expect(gitHandler.message == commitMessage)
    }
    
    @Test("Publishes a binary to Homebrew and verifies the formula file when infomation must be input")
    func testPublishCommandWithInputs() throws {
        let gitHandler = MockGitHandler(assetURL: assetURL)
        let inputs = [versionNumber, releaseNotes, commitMessage]
        let factory = MockContextFactory(runResults: [sha256, assetURL], inputResponses: inputs, permissionResponses: [true], gitHandler: gitHandler)
        
        try createTestTapAndFormula(factory: factory)
        try runCommand(factory)
        
        let formulaFileContents = try #require(try Folder(path: tapFolder.path).file(named: formulaFileName).readAsString())
        
        #expect(formulaFileContents.contains(projectName))
        #expect(formulaFileContents.contains(sha256))
        #expect(formulaFileContents.contains(assetURL))
        #expect(gitHandler.message == commitMessage)
    }
}


// MARK: - Run Command
private extension PublishTests {
    func runCommand(_ factory: MockContextFactory, version: ReleaseVersionInfo? = nil, message: String? = nil) throws {
        var args = ["brew", "publish", "-p", projectFolder.path]
        
        if let version {
            args.append(contentsOf: ["-v", version.arg])
        }
        
        if let message {
            args.append(contentsOf: ["-m", message])
        }
        
        try Nnex.testRun(contextFactory: factory, args: args)
    }
}


// MARK: - Helpers
private extension PublishTests {
    func createTestTapAndFormula(factory: MockContextFactory) throws {
        let context = try factory.makeContext()
        let tap = SwiftDataTap(name: tapName, localPath: tapFolder.path, remotePath: "")
        let formula = SwiftDataFormula(name: projectName, details: "details", homepage: "homepage", license: "MIT", localProjectPath: projectFolder.path, uploadType: .binary)
        
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

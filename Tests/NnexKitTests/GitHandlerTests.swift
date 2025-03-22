//
//  GitHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Testing
import GitShellKit
import NnexSharedTestHelpers
@testable import NnexKit

struct GitHandlerTests {
    private let defaultPath = "/path/to/project"
    private let defaultURL = "https://github.com/username/repo"
    private let previousVersion = "v1.2.3"
    private let releaseAssetURL = "https://github.com/username/repo/releases/latest"
}


// MARK: - Unit Tests
extension GitHandlerTests {
    @Test("Successfully initializes a new Git repository")
    func gitInitSuccess() throws {
        let (sut, shell) = makeSUT(runResults: ["Initialized empty Git repository"])
        
        try sut.gitInit(path: defaultPath)
        
        #expect(shell.printedCommands.count == 4)
        #expect(shell.printedCommands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.printedCommands[1] == makeGitCommand(.gitInit, path: defaultPath))
        #expect(shell.printedCommands[2] == makeGitCommand(.addAll, path: defaultPath))
        #expect(shell.printedCommands[3] == makeGitCommand(.commit("Initial Commit"), path: defaultPath))
    }
    
    @Test("Successfully gets the remote URL")
    func getRemoteURLSuccess() throws {
        let (sut, shell) = makeSUT(runResults: [defaultURL])
        
        let result = try sut.getRemoteURL(path: defaultPath)
        
        #expect(result == defaultURL)
        #expect(shell.printedCommands.count == 1)
        #expect(shell.printedCommands[0] == makeGitCommand(.getRemoteURL, path: defaultPath))
    }
    
    @Test("Successfully retrieves the previous release version")
    func getPreviousReleaseVersionSuccess() throws {
        let (sut, shell) = makeSUT(runResults: [previousVersion])
        
        let result = try sut.getPreviousReleaseVersion(path: defaultPath)
        
        #expect(result == previousVersion)
        #expect(shell.printedCommands.count == 1)
        #expect(shell.printedCommands[0] == makeGitHubCommand(.getPreviousReleaseVersion, path: defaultPath))
    }
    
    @Test("Successfully creates a new GitHub release and retrieves the latest asset URL")
    func createNewReleaseSuccess() throws {
        let version = "v2.0.0"
        let binaryPath = "/path/to/binary"
        let releaseNotes = "Release notes for v2.0.0"
        let (sut, shell) = makeSUT(runResults: [releaseAssetURL])
        
        let result = try sut.createNewRelease(version: version, binaryPath: binaryPath, releaseNotes: releaseNotes, path: defaultPath)
        
        #expect(result == releaseAssetURL)
        #expect(shell.printedCommands.count == 2)
        #expect(shell.printedCommands[0] == makeGitHubCommand(.createNewReleaseWithBinary(version: version, binaryPath: binaryPath, releaseNotes: releaseNotes), path: defaultPath))
        #expect(shell.printedCommands[1] == makeGitHubCommand(.getLatestReleaseAssetURL, path: defaultPath))
    }
    
    @Test("Throws error if initializing Git repository fails")
    func gitInitFails() throws {
        let (sut, _) = makeSUT(throwError: true)
        
        #expect(throws: (any Error).self) {
            try sut.gitInit(path: defaultPath)
        }
    }
    
    @Test("Throws error if getting remote URL fails")
    func getRemoteURLFails() throws {
        let (sut, _) = makeSUT(throwError: true)
        
        #expect(throws: (any Error).self) {
            try sut.getRemoteURL(path: defaultPath)
        }
    }
    
    @Test("Successfully initializes a remote GitHub repository")
    func remoteRepoInitSuccess() throws {
        let visibility: RepoVisibility = .publicRepo
        let runResults = [
            "true",                  // Local git exists
            "",                      // No remote exists
            "main",                  // Current branch
            "creatingRemoteRepo",    // Repo creation command
            defaultURL               // GitHub URL
        ]
        
        let (sut, shell) = makeSUT(runResults: runResults)
        let result = try sut.remoteRepoInit(tapName: "TestTap", path: defaultPath, projectDetails: "A test tap", visibility: visibility)
        
        #expect(result == defaultURL)
        #expect(shell.printedCommands.count == 5)
        #expect(shell.printedCommands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.printedCommands[1] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.printedCommands[2] == makeGitCommand(.getCurrentBranchName, path: defaultPath))
        #expect(shell.printedCommands[3] == makeGitHubCommand(.createRemoteRepo(name: "TestTap", visibility: visibility.rawValue, details: "A test tap"), path: defaultPath))
        #expect(shell.printedCommands[4] == makeGitCommand(.getRemoteURL, path: defaultPath))
    }

}


// MARK: - SUT
private extension GitHandlerTests {
    func makeSUT(runResults: [String] = [], throwError: Bool = false) -> (sut: DefaultGitHandler, shell: MockShell) {
        let shell = MockShell(runResults: runResults, shouldThrowError: throwError)
        let sut = DefaultGitHandler(shell: shell)
        
        return (sut, shell)
    }
}

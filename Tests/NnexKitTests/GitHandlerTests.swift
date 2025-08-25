//
//  GitHandlerTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Testing
import GitShellKit
import NnShellKit
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
        
        #expect(shell.executedCommands.count == 4)
        #expect(shell.executedCommands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.executedCommands[1] == makeGitCommand(.gitInit, path: defaultPath))
        #expect(shell.executedCommands[2] == makeGitCommand(.addAll, path: defaultPath))
        #expect(shell.executedCommands[3] == makeGitCommand(.commit(message: "Initial Commit"), path: defaultPath))
    }
    
    @Test("Successfully gets the remote URL")
    func getRemoteURLSuccess() throws {
        let (sut, shell) = makeSUT(runResults: [defaultURL])
        
        let result = try sut.getRemoteURL(path: defaultPath)
        
        #expect(result == defaultURL)
        #expect(shell.executedCommands.count == 1)
        #expect(shell.executedCommands[0] == makeGitCommand(.getRemoteURL, path: defaultPath))
    }
    
    @Test("Successfully retrieves the previous release version")
    func getPreviousReleaseVersionSuccess() throws {
        let (sut, shell) = makeSUT(runResults: [previousVersion])
        
        let result = try sut.getPreviousReleaseVersion(path: defaultPath)
        
        #expect(result == previousVersion)
        #expect(shell.executedCommands.count == 1)
        #expect(shell.executedCommands[0] == makeGitHubCommand(.getPreviousReleaseVersion, path: defaultPath))
    }
    
    @Test("Successfully creates a new GitHub release and retrieves asset URLs")
    func createNewReleaseSuccess() throws {
        let version = "v2.0.0"
        let binaryPath = "/path/to/binary"
        let releaseNoteInfo = ReleaseNoteInfo(content: "Release notes for v2.0.0", isFromFile: false)
        let (sut, shell) = makeSUT(runResults: ["", releaseAssetURL]) // First result for create release, second for get asset URLs
        
        let result = try sut.createNewRelease(version: version, binaryPath: binaryPath, additionalBinaryPaths: [], releaseNoteInfo: releaseNoteInfo, path: defaultPath)
        
        #expect(result.count == 1)
        #expect(result.first == releaseAssetURL)
        #expect(shell.executedCommands.count == 2)
        #expect(shell.executedCommands[0] == "cd \"\(defaultPath)\" && gh release create \(version) \"\(binaryPath)\" --title \"\(version)\" --notes \"\(releaseNoteInfo.content)\"")
        #expect(shell.executedCommands[1] == "cd \"\(defaultPath)\" && gh release view \(version) --json assets --jq '.assets[].url'")
    }
    
    @Test("Successfully creates a new GitHub release with additional assets")
    func createNewReleaseWithAdditionalAssets() throws {
        let version = "v2.0.0"
        let binaryPath = "/path/to/binary"
        let additionalPaths = ["/path/to/binary2", "/path/to/binary3"]
        let releaseNoteInfo = ReleaseNoteInfo(content: "Release notes for v2.0.0", isFromFile: false)
        let additionalURL1 = "https://github.com/username/repo/releases/latest/binary2"
        let additionalURL2 = "https://github.com/username/repo/releases/latest/binary3"
        let allURLsOutput = "\(releaseAssetURL)\n\(additionalURL1)\n\(additionalURL2)"
        let (sut, shell) = makeSUT(runResults: ["", allURLsOutput]) // create, view all assets
        
        let result = try sut.createNewRelease(version: version, binaryPath: binaryPath, additionalBinaryPaths: additionalPaths, releaseNoteInfo: releaseNoteInfo, path: defaultPath)
        
        #expect(result.count == 3)
        #expect(result[0] == releaseAssetURL)
        #expect(result[1] == additionalURL1)
        #expect(result[2] == additionalURL2)
        #expect(shell.executedCommands.count == 2)
        #expect(shell.executedCommands[0] == "cd \"\(defaultPath)\" && gh release create \(version) \"\(binaryPath)\" \"/path/to/binary2\" \"/path/to/binary3\" --title \"\(version)\" --notes \"\(releaseNoteInfo.content)\"")
        #expect(shell.executedCommands[1] == "cd \"\(defaultPath)\" && gh release view \(version) --json assets --jq '.assets[].url'")
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
        #expect(shell.executedCommands.count == 5)
        #expect(shell.executedCommands[0] == makeGitCommand(.localGitCheck, path: defaultPath))
        #expect(shell.executedCommands[1] == makeGitCommand(.checkForRemote, path: defaultPath))
        #expect(shell.executedCommands[2] == makeGitCommand(.getCurrentBranchName, path: defaultPath))
        #expect(shell.executedCommands[3] == makeGitHubCommand(.createRemoteRepo(name: "TestTap", visibility: visibility.rawValue, details: "A test tap"), path: defaultPath))
        #expect(shell.executedCommands[4] == makeGitCommand(.getRemoteURL, path: defaultPath))
    }
    
    @Test("Successfully commits and pushes changes")
    func commitAndPushSuccess() throws {
        let commitMessage = "Initial commit"
        let (sut, shell) = makeSUT()

        try sut.commitAndPush(message: commitMessage, path: defaultPath)

        #expect(shell.executedCommands.count == 3)
        #expect(shell.executedCommands[0] == makeGitCommand(.addAll, path: defaultPath))
        #expect(shell.executedCommands[1] == makeGitCommand(.commit(message: commitMessage), path: defaultPath))
        #expect(shell.executedCommands[2] == makeGitCommand(.push, path: defaultPath))
    }
}


// MARK: - SUT
private extension GitHandlerTests {
    func makeSUT(runResults: [String] = [], throwError: Bool = false) -> (sut: DefaultGitHandler, shell: MockShell) {
        let shell = MockShell(results: runResults, shouldThrowError: throwError)
        let sut = DefaultGitHandler(shell: shell)
        
        return (sut, shell)
    }
}

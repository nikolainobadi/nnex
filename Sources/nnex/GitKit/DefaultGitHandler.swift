//
//  DefaultGitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import GitShellKit

struct DefaultGitHandler {
    private let shell: Shell
    private let gitShell: GitShell
    
    init(shell: Shell) {
        self.shell = shell
        self.gitShell = GitShellAdapter(shell: shell)
    }
}


// MARK: - Actions
extension DefaultGitHandler: GitHandler {
    func commitAndPush(message: String, path: String) throws {
        try shell.runAndPrint(makeGitCommand(.commit(message), path: path))
        try shell.runAndPrint(makeGitCommand(.push, path: path))
    }
    
    func getRemoteURL(path: String) throws -> String {
        return try gitShell.getGitHubURL(at: path)
    }
    
    func getPreviousReleaseVersion(path: String) throws -> String {
        return try shell.run(makeGitHubCommand(.getPreviousReleaseVersion, path: path))
    }
    
    func gitInit(path: String) throws {
        try GitStarter(path: path, shell: gitShell).gitInit()
    }
    
    func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String {
        let info = RepoInfo(name: tapName, details: projectDetails, visibility: visibility, canUploadFromNonMainBranch: false)
        
        return try GitHubRepoStarter(path: path, shell: gitShell, repoInfo: info).repoInit()
    }
    
    func createNewRelease(version: String, binaryPath: String, releaseNotes: String, path: String) throws -> String {
        let command = makeGitHubCommand(.createNewReleaseWithBinary(version: version, binaryPath: binaryPath, releaseNotes: releaseNotes), path: path)
        
        try shell.runAndPrint(command)
        
        return try shell.run(makeGitHubCommand(.getLatestReleaseAssetURL, path: path))
    }
    
    func ghVerification() throws {
        let output = try shell.run("which gh")
        
        if output.contains("not found") {
            print("""
            GitHub CLI (gh) is not installed on your system. Please install it to proceed.
            
            To install using Homebrew (recommended since 'nnex' is designed to streamline Homebrew Taps/Formula distribution):
            1. Make sure Homebrew is installed:
               brew --version
            2. If Homebrew is not installed, run:
               /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            3. Install GitHub CLI:
               brew install gh
            4. Verify installation:
               gh --version
            
            Alternatively, install directly using the official script:
            curl -fsSL https://cli.github.com/install.sh | sudo bash
            
            Once installed, please rerun this command.
            """)
            
            throw NnexError.missingGitHubCLI
        }
    }
}


// MARK: - Dependencies
protocol GitHandler {
    func ghVerification() throws
    func gitInit(path: String) throws
    func getRemoteURL(path: String) throws -> String
    func commitAndPush(message: String, path: String) throws
    func getPreviousReleaseVersion(path: String) throws -> String
    func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String
    func createNewRelease(version: String, binaryPath: String, releaseNotes: String, path: String) throws -> String
}

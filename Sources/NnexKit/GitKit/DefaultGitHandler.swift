//
//  DefaultGitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import GitShellKit
import NnShellKit

/// Default implementation of the GitHandler protocol, providing Git-related operations.
public struct DefaultGitHandler {
    private let shell: any Shell
    private let gitShell: GitShell

    /// Initializes a new instance of DefaultGitHandler with the specified shell.
    /// - Parameter shell: The shell used to execute commands.
    public init(shell: any Shell) {
        self.shell = shell
        self.gitShell = GitShellAdapter(shell: shell)
    }
}


// MARK: - Actions
extension DefaultGitHandler: GitHandler {
    /// Adds all changes, commits with a given message, and pushes to the remote repository.
    /// - Parameters:
    ///   - message: The commit message describing the changes.
    ///   - path: The file path of the repository.
    public func commitAndPush(message: String, path: String) throws {
        _ = try shell.bash(makeGitCommand(.addAll, path: path))
        _ = try shell.bash(makeGitCommand(.commit(message: message), path: path))
        _ = try shell.bash(makeGitCommand(.push, path: path))
    }

    /// Retrieves the remote URL of the repository located at the given path.
    /// - Parameter path: The file path of the repository.
    /// - Returns: A string representing the remote URL.
    public func getRemoteURL(path: String) throws -> String {
        return try gitShell.getGitHubURL(at: path)
    }

    /// Retrieves the previous release version from the repository at the given path.
    /// - Parameter path: The file path of the repository.
    /// - Returns: A string representing the previous release version.
    public func getPreviousReleaseVersion(path: String) throws -> String {
        return try shell.bash(makeGitHubCommand(.getPreviousReleaseVersion, path: path))
    }

    /// Initializes a new Git repository at the given path.
    /// - Parameter path: The file path where the repository should be initialized.
    public func gitInit(path: String) throws {
        try GitStarter(path: path, shell: gitShell).gitInit()
    }

    /// Initializes a new remote repository on GitHub with specified details and returns the repository URL.
    /// - Parameters:
    ///   - tapName: The name of the remote repository.
    ///   - path: The file path where the repository is located.
    ///   - projectDetails: A description of the repository.
    ///   - visibility: The visibility of the repository (public or private).
    /// - Returns: A string representing the repository URL.
    public func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String {
        let info = RepoInfo(name: tapName, details: projectDetails, visibility: visibility, canUploadFromNonMainBranch: false)
        return try GitHubRepoStarter(path: path, shell: gitShell, repoInfo: info).repoInit()
    }

    /// Creates a new release with a binary at the specified path and returns the release URL.
    /// - Parameters:
    ///   - version: The version number for the release.
    ///   - binaryPath: The file path to the binary file.
    ///   - releaseNotes: A string containing release notes.
    ///   - path: The file path of the repository.
    /// - Returns: A string representing the release URL.
    public func createNewRelease(version: String, binaryPath: String, releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> String {
        let command = makeGitHubCommand(.createNewReleaseWithBinary(version: version, binaryPath: binaryPath, releaseNoteInfo: releaseNoteInfo), path: path)
        _ = try shell.bash(command)
        return try shell.bash(makeGitHubCommand(.getLatestReleaseAssetURL, path: path))
    }

    /// Verifies if the GitHub CLI (gh) is installed and provides installation instructions if not.
    public func ghVerification() throws {
        if try shell.bash("which gh").contains("not found") {
            throw NnexError.missingGitHubCLI
        }
    }
}

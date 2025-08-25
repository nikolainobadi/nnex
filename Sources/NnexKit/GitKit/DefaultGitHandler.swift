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

    /// Creates a new release with one or more binaries and returns all asset URLs.
    /// - Parameters:
    ///   - version: The version number for the release.
    ///   - binaryPath: The file path to the primary binary file.
    ///   - additionalBinaryPaths: Optional additional binary paths to upload to the same release.
    ///   - releaseNoteInfo: Information for generating release notes.
    ///   - path: The file path of the repository.
    /// - Returns: An array of asset URLs, with the primary asset URL first, followed by additional asset URLs.
    public func createNewRelease(version: String, binaryPath: String, additionalBinaryPaths: [String], releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> [String] {
        // Create the primary release with the main binary
        let primaryAssetURL = try createPrimaryRelease(version: version, binaryPath: binaryPath, releaseNoteInfo: releaseNoteInfo, path: path)
        
        // Upload additional binaries to the same release if provided
        var allAssetURLs = [primaryAssetURL]
        if !additionalBinaryPaths.isEmpty {
            let additionalAssetURLs = try uploadAdditionalAssets(tag: version, assetPaths: additionalBinaryPaths, projectPath: path)
            allAssetURLs.append(contentsOf: additionalAssetURLs)
        }
        
        return allAssetURLs
    }

    /// Verifies if the GitHub CLI (gh) is installed and provides installation instructions if not.
    public func ghVerification() throws {
        if try shell.bash("which gh").contains("not found") {
            throw NnexError.missingGitHubCLI
        }
    }
}


// MARK: - Private Methods
private extension DefaultGitHandler {
    /// Creates the primary release with the main binary and release notes.
    func createPrimaryRelease(version: String, binaryPath: String, releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> String {
        // Build the release notes parameter
        let notesParam: String
        if releaseNoteInfo.isFromFile {
            notesParam = "--notes-file \"\(releaseNoteInfo.content)\""
        } else {
            notesParam = "--notes \"\(releaseNoteInfo.content)\""
        }
        
        // Create the release and upload the primary binary
        let createCmd = "cd \"\(path)\" && gh release create \(version) \"\(binaryPath)\" --title \"\(version)\" \(notesParam)"
        _ = try shell.bash(createCmd)
        
        // Get the asset URL for the primary binary
        let listCmd = "cd \"\(path)\" && gh release view \(version) --json assets --jq '.assets[0].url'"
        return try shell.bash(listCmd)
    }
    
    /// Uses GitHub CLI to upload additional assets to an existing release tag and returns their asset URLs.
    func uploadAdditionalAssets(tag: String, assetPaths: [String], projectPath: String) throws -> [String] {
        // Upload all additional assets
        let quotedPaths = assetPaths.map { "\"\($0)\"" }.joined(separator: " ")
        let uploadCmd = "cd \"\(projectPath)\" && gh release upload \(tag) \(quotedPaths) --clobber"
        _ = try shell.bash(uploadCmd)
        
        // Get asset URLs for the uploaded files
        let listCmd = "cd \"\(projectPath)\" && gh release view \(tag) --json assets --jq '.assets[].url'"
        let allAssetURLs = try shell.bash(listCmd).components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Return only the additional asset URLs (excluding the first one which is the primary)
        return Array(allAssetURLs.dropFirst())
    }
}

//
//  GitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import GitShellKit

/// Protocol defining Git-related operations.
public protocol GitHandler {
    /// Verifies the installation of the GitHub CLI (gh).
    func ghVerification() throws
    
    /// Initializes a new Git repository at the given path.
    /// - Parameter path: The file path where the repository should be initialized.
    func gitInit(path: String) throws
    
    /// Retrieves the remote URL of the repository located at the given path.
    /// - Parameter path: The file path of the repository.
    /// - Returns: A string representing the remote URL.
    func getRemoteURL(path: String) throws -> String
    
    /// Commits changes and pushes them to the remote repository with the given message.
    /// - Parameters:
    ///   - message: The commit message describing the changes.
    ///   - path: The file path of the repository.
    func commitAndPush(message: String, path: String) throws
    
    /// Retrieves the previous release version from the repository at the given path.
    /// - Parameter path: The file path of the repository.
    /// - Returns: A string representing the previous release version.
    func getPreviousReleaseVersion(path: String) throws -> String
    
    /// Initializes a new remote repository on GitHub with the specified details.
    /// - Parameters:
    ///   - tapName: The name of the remote repository.
    ///   - path: The file path where the repository is located.
    ///   - projectDetails: A description of the repository.
    ///   - visibility: The visibility of the repository (public or private).
    /// - Returns: A string representing the repository URL.
    func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String
    
    /// Creates a new release with one or more binaries and returns all asset URLs.
    /// - Parameters:
    ///   - version: The version number for the release.
    ///   - binaryPath: The file path to the primary binary file.
    ///   - additionalBinaryPaths: Optional additional binary paths to upload to the same release.
    ///   - releaseNoteInfo: Information for generating release notes.
    ///   - path: The file path of the repository.
    /// - Returns: An array of asset URLs, with the primary asset URL first, followed by additional asset URLs.
    func createNewRelease(version: String, binaryPath: String, additionalBinaryPaths: [String], releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> [String]
}

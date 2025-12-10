//
//  DefaultGitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import GitShellKit

public struct DefaultGitHandler {
    private let shell: any NnexShell

    public init(shell: any NnexShell) {
        self.shell = shell
    }
}


// MARK: - Actions
extension DefaultGitHandler: GitHandler {
    /// Adds all changes, commits with a given message, and pushes to the remote repository.
    /// - Parameters:
    ///   - message: The commit message describing the changes.
    ///   - path: The file path of the repository.
    public func commitAndPush(message: String, path: String) throws {
        try shell.runAndPrint(bash: makeGitCommand(.addAll, path: path))
        try shell.runAndPrint(bash: makeGitCommand(.commit(message: message), path: path))
        try shell.runAndPrint(bash: makeGitCommand(.push, path: path))
    }

    /// Retrieves the remote URL of the repository located at the given path.
    /// - Parameter path: The file path of the repository.
    /// - Returns: A string representing the remote URL.
    public func getRemoteURL(path: String) throws -> String {
        return try shell.getGitHubURL(at: path)
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
        try GitStarter(path: path, shell: shell).gitInit()
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
        return try GitHubRepoStarter(path: path, shell: shell, repoInfo: info).repoInit()
    }

    /// Creates a new release with one or more archived binaries and returns all asset URLs.
    /// - Parameters:
    ///   - version: The version number for the release.
    ///   - archivedBinaries: The archived binary files to upload to the release.
    ///   - releaseNoteInfo: Information for generating release notes.
    ///   - path: The file path of the repository.
    /// - Returns: An array of asset URLs, with the primary asset URL first, followed by additional asset URLs.
    public func createNewRelease(version: String, archivedBinaries: [ArchivedBinary], releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> [String] {
        return try createReleaseWithAllBinaries(version: version, archivedBinaries: archivedBinaries, releaseNoteInfo: releaseNoteInfo, path: path)
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
    /// Creates a release with all binaries uploaded simultaneously in a single command.
    func createReleaseWithAllBinaries(version: String, archivedBinaries: [ArchivedBinary], releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> [String] {
        // Build the release notes parameter
        let notesParam: String
        if releaseNoteInfo.isFromFile {
            notesParam = "--notes-file \"\(releaseNoteInfo.content)\""
        } else {
            notesParam = "--notes \"\(releaseNoteInfo.content)\""
        }
        
        // Create the release and upload all archives at once
        let quotedArchivePaths = archivedBinaries.map { "\"\($0.archivePath)\"" }.joined(separator: " ")
        let createCmd = "cd \"\(path)\" && gh release create \(version) \(quotedArchivePaths) --title \"\(version)\" \(notesParam)"
        try shell.runAndPrint(bash: createCmd)
        
        // Clean up archive files after upload
        let archiver = BinaryArchiver(shell: shell)
        try archiver.cleanup(archivedBinaries)
        
        // Get all asset URLs
        let listCmd = "cd \"\(path)\" && gh release view \(version) --json assets --jq '.assets[].url'"
        let allAssetURLs = try shell.bash(listCmd).components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        return allAssetURLs
    }
}

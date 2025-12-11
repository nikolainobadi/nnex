//
//  DefaultGitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Foundation
import GitShellKit

public struct DefaultGitHandler {
    private let shell: any NnexShell

    public init(shell: any NnexShell) {
        self.shell = shell
    }
}


// MARK: - Actions
extension DefaultGitHandler: GitHandler {
    public func commitAndPush(message: String, path: String) throws {
        try shell.runAndPrint(bash: makeGitCommand(.addAll, path: path))
        try shell.runAndPrint(bash: makeGitCommand(.commit(message: message), path: path))
        try shell.runAndPrint(bash: makeGitCommand(.push, path: path))
    }

    public func getRemoteURL(path: String) throws -> String {
        return try shell.getGitHubURL(at: path)
    }

    public func getPreviousReleaseVersion(path: String) throws -> String {
        return try shell.bash(makeGitHubCommand(.getPreviousReleaseVersion, path: path))
    }

    public func gitInit(path: String) throws {
        try GitStarter(path: path, shell: shell).gitInit()
    }

    public func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String {
        let info = RepoInfo(name: tapName, details: projectDetails, visibility: visibility, canUploadFromNonMainBranch: false)
        return try GitHubRepoStarter(path: path, shell: shell, repoInfo: info).repoInit()
    }

    public func createNewRelease(version: String, archivedBinaries: [ArchivedBinary], releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> [String] {
        return try createReleaseWithAllBinaries(version: version, archivedBinaries: archivedBinaries, releaseNoteInfo: releaseNoteInfo, path: path)
    }

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

//
//  ChangeLogInfoLoader.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Foundation
import NnShellKit

/// Loads changelog information by executing git commands to extract commit history, file changes, and diffs.
public struct ChangeLogInfoLoader {
    private let shell: any Shell
    
    /// Initializes a new ChangeLogInfoLoader instance.
    /// - Parameter shell: The shell instance for executing git commands.
    public init(shell: any Shell) {
        self.shell = shell
    }
}


// MARK: - Load
public extension ChangeLogInfoLoader {
    /// Loads comprehensive changelog information from git history.
    /// - Returns: A ChangeLogInfo instance containing all changelog data.
    /// - Throws: An error if any git command fails or if the repository state is invalid.
    func loadChangeLogInfo() throws -> ChangeLogInfo {
        let previousTag = try getPreviousTag()
        let commits = try getCommits(since: previousTag)
        let filesChanged = try getFilesChanged(since: previousTag)
        let changeStats = try getChangeStats(since: previousTag)
        let compactDiff = try getCompactDiff(since: previousTag)
        
        return ChangeLogInfo(
            previousTag: previousTag,
            commits: commits,
            filesChanged: filesChanged,
            changeStats: changeStats,
            compactDiff: compactDiff
        )
    }
}


// MARK: - Private Methods
private extension ChangeLogInfoLoader {
    /// Finds the previous git tag or falls back to the first commit if no tags exist.
    /// - Returns: The previous tag or first commit hash.
    /// - Throws: An error if the git command fails.
    func getPreviousTag() throws -> String {
        do {
            let tag = try shell.bash("git describe --tags --abbrev=0 HEAD^")
            return tag.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            // Fallback to first commit if no tags exist
            let firstCommit = try shell.bash("git rev-list --max-parents=0 HEAD")
            return firstCommit.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// Gets the list of commit messages since the previous tag.
    /// - Parameter previousTag: The previous tag or commit to compare against.
    /// - Returns: An array of commit messages.
    /// - Throws: An error if the git command fails.
    func getCommits(since previousTag: String) throws -> [String] {
        let output = try shell.bash("git log \(previousTag)..HEAD --pretty=format:'%s'")
        return output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Gets the list of files changed since the previous tag with their status.
    /// - Parameter previousTag: The previous tag or commit to compare against.
    /// - Returns: An array of FileChange instances.
    /// - Throws: An error if the git command fails.
    func getFilesChanged(since previousTag: String) throws -> [FileChange] {
        let output = try shell.bash("git diff --name-status \(previousTag)..HEAD")
        return output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { line in
                let components = line.components(separatedBy: .whitespaces)
                guard components.count >= 2 else { return nil }
                let status = components[0]
                let filename = components[1...].joined(separator: " ")
                return FileChange(status: status, filename: filename)
            }
    }
    
    /// Gets the change statistics (files changed, insertions, deletions) since the previous tag.
    /// - Parameter previousTag: The previous tag or commit to compare against.
    /// - Returns: A string containing the diff statistics.
    /// - Throws: An error if the git command fails.
    func getChangeStats(since previousTag: String) throws -> String {
        let output = try shell.bash("git diff --stat \(previousTag)..HEAD")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Gets a compact unified diff with function context, limited to 800 lines.
    /// - Parameter previousTag: The previous tag or commit to compare against.
    /// - Returns: A string containing the compact diff.
    /// - Throws: An error if the git command fails.
    func getCompactDiff(since previousTag: String) throws -> String {
        let output = try shell.bash("git diff --unified=0 --function-context \(previousTag)..HEAD | head -n 800")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
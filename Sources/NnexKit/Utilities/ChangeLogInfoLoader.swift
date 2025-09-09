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
        
        return .init(previousTag: previousTag, commits: commits, filesChanged: filesChanged, changeStats: changeStats, compactDiff: compactDiff)
    }
}


// MARK: - Private Methods
private extension ChangeLogInfoLoader {
    /// Finds the previous git tag or falls back to the first commit if no tags exist.
    /// - Returns: The previous tag or first commit hash.
    /// - Throws: An error if the git command fails.
    func getPreviousTag() throws -> String {
        do {
            if let tag = try? shell.bash("git describe --tags --abbrev=0 HEAD^").trimmingCharacters(in: .whitespacesAndNewlines),
               !tag.isEmpty {
                return tag
            }
            // Fallback to first commit if no tags exist or tag is empty
            let firstCommit = try shell.bash("git rev-list --max-parents=0 HEAD")
            return firstCommit.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            let firstCommit = try shell.bash("git rev-list --max-parents=0 HEAD")
            return firstCommit.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// Gets the list of commit messages since the previous tag.
    /// - Parameter previousTag: The previous tag or commit to compare against.
    /// - Returns: An array of commit messages.
    /// - Throws: An error if the git command fails.
    func getCommits(since previousTag: String) throws -> [String] {
        let output = try shell.bash("GIT_PAGER= git log \(previousTag)..HEAD --pretty=format:%s")
        return output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Gets the list of files changed since the previous tag with their status.
    /// - Parameter previousTag: The previous tag or commit to compare against.
    /// - Returns: An array of FileChange instances.
    /// - Throws: An error if the git command fails.
    func getFilesChanged(since previousTag: String) throws -> [FileChange] {
        // -z => NUL separated; name-status fields are tab-separated per record
        let output = try shell.bash("GIT_PAGER= git diff --name-status -z \(previousTag)..HEAD")
        let parts = output.split(separator: "\0").map(String.init)
        var items: [FileChange] = []

        var i = 0
        while i < parts.count {
            // status and first path are in the same NUL-delimited record but tab-separated
            let fields = parts[i].split(separator: "\t").map(String.init)
            guard let status = fields.first else { break }

            switch status.prefix(1) {
            case "R", "C": // rename/copy => status, old, new
                // fields may be: [ "R100", "oldpath", "newpath" ] in one record
                if fields.count >= 3 {
                    items.append(FileChange(status: String(status), filename: fields[2]))
                } else {
                    // Some git versions emit status + old in first record, new in next; handle gracefully
                    if i + 1 < parts.count {
                        items.append(FileChange(status: String(status), filename: parts[i + 1]))
                        i += 1
                    }
                }
            default:
                // A/M/D etc: fields[1] is the path
                let filename = fields.count >= 2 ? fields[1] : (fields.first ?? "")
                items.append(FileChange(status: String(status), filename: filename))
            }
            i += 1
        }
        return items
    }
    
    /// Gets the change statistics (files changed, insertions, deletions) since the previous tag.
    /// - Parameter previousTag: The previous tag or commit to compare against.
    /// - Returns: A string containing the diff statistics.
    /// - Throws: An error if the git command fails.
    func getChangeStats(since previousTag: String) throws -> String {
        let output = try shell.bash("GIT_PAGER= git diff --no-color --no-ext-diff --stat \(previousTag)..HEAD")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Gets a compact unified diff with function context, limited to 800 lines.
    /// - Parameter previousTag: The previous tag or commit to compare against.
    /// - Returns: A string containing the compact diff.
    /// - Throws: An error if the git command fails.
    func getCompactDiff(since previousTag: String) throws -> String {
        let output = try shell.bash("bash -lc 'GIT_PAGER= git diff --no-color --no-ext-diff --diff-algorithm=histogram --unified=0 --function-context \(previousTag)..HEAD | head -c 120000'")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

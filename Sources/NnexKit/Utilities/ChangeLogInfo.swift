//
//  ChangeLogInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Foundation

/// Represents a file change in a git diff with its status and filename.
public struct FileChange {
    /// The status of the file change (A=Added, M=Modified, D=Deleted, etc.)
    public let status: String
    
    /// The filename that was changed
    public let filename: String
    
    /// Initializes a new FileChange instance.
    /// - Parameters:
    ///   - status: The status of the file change.
    ///   - filename: The filename that was changed.
    public init(status: String, filename: String) {
        self.status = status
        self.filename = filename
    }
}

/// Contains comprehensive changelog information extracted from git history.
public struct ChangeLogInfo {
    /// The previous git tag or commit hash used as the base for comparison
    public let previousTag: String
    
    /// List of commit messages since the previous tag
    public let commits: [String]
    
    /// List of files that were changed with their status
    public let filesChanged: [FileChange]
    
    /// Git diff statistics showing files changed, insertions, and deletions
    public let changeStats: String
    
    /// Compact unified diff with function context (limited to prevent excessive output)
    public let compactDiff: String
    
    /// Initializes a new ChangeLogInfo instance.
    /// - Parameters:
    ///   - previousTag: The previous git tag or commit hash.
    ///   - commits: List of commit messages.
    ///   - filesChanged: List of file changes.
    ///   - changeStats: Git diff statistics.
    ///   - compactDiff: Compact unified diff.
    public init(previousTag: String, commits: [String], filesChanged: [FileChange], changeStats: String, compactDiff: String) {
        self.previousTag = previousTag
        self.commits = commits
        self.filesChanged = filesChanged
        self.changeStats = changeStats
        self.compactDiff = compactDiff
    }
}
//
//  NnexError.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

public enum NnexError: Error {
    /// The specified tap could not be found.
    case missingTap
    
    /// The SHA256 hash could not be obtained.
    case missingSha256
    
    /// The provided tap name is not valid.
    case invalidTapName
    
    /// The GitHub CLI (gh) is not installed or could not be found.
    case missingGitHubCLI
    
    /// The shell command failed to execute successfully.
    case shellCommandFailed
    
    /// The version number format is invalid.
    case invalidVersionNumber
    
    /// The GitHub username is missing or not configured.
    case missingGitHubUsername
    
    /// There is no previous version available to increment.
    case noPreviousVersionToIncrement
    
    case missingExecutable
}

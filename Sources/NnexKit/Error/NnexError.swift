//
//  NnexError.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

public enum NnexError: Error {
    case missingTap
    case missingSha256
    case invalidTapName
    case missingGitHubCLI
    case shellCommandFailed
    case invalidVersionNumber
    case missingGitHubUsername
    case noPreviousVersionToIncrement
}

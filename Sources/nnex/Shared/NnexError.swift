//
//  NnexError.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

enum NnexError: Error {
    case missingTap
    case missingSha256
    case invalidTapName
    case missingGitHubCLI
    case noPreviousVersion
    case shellCommandFailed
    case invalidVersionNumber
    case missingGitHubUsername
}

//
//  AIChangeLogError.swift
//  nnex
//
//  Created by Nikolai Nobadi on 9/8/25.
//

import Foundation

public enum AIChangeLogError: Error, LocalizedError {
    case missingClaudeCLI
    case emptyClaudeResponse
    case fileOperationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingClaudeCLI:
            return "Claude CLI is not installed. Please install it first: https://claude.ai/cli"
        case .emptyClaudeResponse:
            return "Claude returned an empty response. Please try again."
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        }
    }
}

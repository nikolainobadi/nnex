//
//  BuildExecutionError.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Foundation

enum BuildExecutionError: Error, LocalizedError, Equatable {
    case failedToSelectExecutable(reason: String)
    case invalidCustomPath(path: String)
    case buildCancelledByUser
    
    var errorDescription: String? {
        switch self {
        case .failedToSelectExecutable(let reason):
            return "Failed to select executable: \(reason)"
        case .invalidCustomPath(let path):
            return "The specified path '\(path)' does not exist or is not accessible."
        case .buildCancelledByUser:
            return "Build cancelled by user."
        }
    }
}
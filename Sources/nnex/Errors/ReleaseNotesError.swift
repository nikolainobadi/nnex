//
//  ReleaseNotesError.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/20/25.
//

import Foundation

enum ReleaseNotesError: Error, LocalizedError, Equatable {
    case emptyFileAfterRetry(filePath: String)
    case missingAIRequirements
    
    var errorDescription: String? {
        switch self {
        case .emptyFileAfterRetry(let filePath):
            return "File at '\(filePath)' is still empty after retry. Please add content to the file or choose a different option."
        case .missingAIRequirements:
            return "AI release notes generation requires release number, project path, and shell instance."
        }
    }
}

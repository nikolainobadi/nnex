//
//  ExportError.swift
//  nnex
//
//  Created by Claude Code on 8/10/25.
//

import Foundation

enum ExportError: Error, LocalizedError {
    case noArchivesFound
    case invalidArchive(path: String)
    case noAppFoundInArchive(path: String)
    case notarizationFailed(reason: String)
    case staplingFailed(reason: String)
    case exportFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .noArchivesFound:
            return "No .xcarchive files found in common locations (./build/archives, ~/Library/Developer/Xcode/Archives). Please specify an archive path with --archive."
        case .invalidArchive(let path):
            return "Invalid archive at '\(path)'. Make sure the path points to a valid .xcarchive."
        case .noAppFoundInArchive(let path):
            return "No .app bundle found in archive '\(path)'. The archive may be corrupted or incomplete."
        case .notarizationFailed(let reason):
            return "Notarization failed: \(reason)"
        case .staplingFailed(let reason):
            return "Stapling failed: \(reason)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }
}
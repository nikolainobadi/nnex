//
//  ExecutableNameResolverError.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Foundation

public enum ExecutableNameResolverError: Error, LocalizedError, Equatable {
    case missingPackageSwift(path: String)
    case failedToReadPackageSwift(reason: String)
    case emptyPackageSwift
    case failedToParseExecutables(reason: String)
    case noExecutablesFound
    
    public var errorDescription: String? {
        switch self {
        case .missingPackageSwift(let path):
            return "No Package.swift file found in '\(path)'. This does not appear to be a Swift package."
        case .failedToReadPackageSwift(let reason):
            return "Failed to read Package.swift file: \(reason)"
        case .emptyPackageSwift:
            return "Package.swift file is empty or contains only whitespace."
        case .failedToParseExecutables(let reason):
            return "Failed to parse executable targets from Package.swift: \(reason)"
        case .noExecutablesFound:
            return "No executable targets found in Package.swift. Make sure your package defines at least one executable product."
        }
    }
}

//
//  ReleaseArchitecture.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Represents the architecture of a release build.
public enum ReleaseArchitecture {
    /// ARM architecture (arm64).
    case arm

    /// Intel architecture (x86_64).
    case intel

    /// Returns the architecture name as a string.
    var name: String {
        switch self {
        case .arm:
            return "arm64"
        case .intel:
            return "x86_64"
        }
    }
}

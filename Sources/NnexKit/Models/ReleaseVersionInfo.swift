//
//  ReleaseVersionInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

/// Represents version information for a release, including version numbers and increments.
public enum ReleaseVersionInfo: Sendable {
    /// A specific version string (e.g., "1.0.0").
    case version(String)

    /// An increment to a specific part of the version number (major, minor, or patch).
    case increment(VersionPart)

    /// Represents parts of a version number (major, minor, patch).
    public enum VersionPart: String, CaseIterable, Sendable {
        /// Major version part.
        case major

        /// Minor version part.
        case minor

        /// Patch version part.
        case patch

        /// Initializes a VersionPart from a string, ignoring case.
        /// - Parameter string: The string representation of the version part.
        public init?(string: String) {
            self.init(rawValue: string.lowercased())
        }
    }

    /// Initializes a ReleaseVersionInfo instance from a version or version part.
    /// - Parameter argument: The version string or version part to be parsed.
    public init?(argument: String) {
        if let versionPart = VersionPart(rawValue: argument) {
            self = .increment(versionPart)
        } else {
            self = .version(argument)
        }
    }
}

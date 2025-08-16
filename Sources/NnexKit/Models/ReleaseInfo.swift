//
//  ReleaseInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import GitCommandGen

/// Contains information related to a release, including binary path, project path, release notes, and version information.
public struct ReleaseInfo {
    /// The path to the binary file.
    public let binaryPath: String

    /// The path to the project associated with the release.
    public let projectPath: String

    /// The release notes describing the release.
    public let releaseNoteInfo: ReleaseNoteInfo

    /// The previous version of the release, if available.
    public let previousVersion: String?

    /// Information about the release version, including version number or increment.
    public let versionInfo: ReleaseVersionInfo

    /// Initializes a new instance of ReleaseInfo.
    /// - Parameters:
    ///   - binaryPath: The path to the binary file.
    ///   - projectPath: The path to the project associated with the release.
    ///   - releaseNotes: A description of the release.
    ///   - previousVersion: The previous release version, if applicable.
    ///   - versionInfo: The version information for the release.
    public init(binaryPath: String, projectPath: String, releaseNoteInfo: ReleaseNoteInfo, previousVersion: String?, versionInfo: ReleaseVersionInfo) {
        self.binaryPath = binaryPath
        self.projectPath = projectPath
        self.releaseNoteInfo = releaseNoteInfo
        self.previousVersion = previousVersion
        self.versionInfo = versionInfo
    }
}

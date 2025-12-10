//
//  ReleaseInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import GitCommandGen

public struct ReleaseInfo {
    public let projectPath: String
    public let releaseNoteInfo: ReleaseNoteInfo
    public let previousVersion: String?
    public let versionInfo: ReleaseVersionInfo

    /// Initializes a new instance of ReleaseInfo.
    /// - Parameters:
    ///   - projectPath: The path to the project associated with the release.
    ///   - releaseNotes: A description of the release.
    ///   - previousVersion: The previous release version, if applicable.
    ///   - versionInfo: The version information for the release.
    public init(projectPath: String, releaseNoteInfo: ReleaseNoteInfo, previousVersion: String?, versionInfo: ReleaseVersionInfo) {
        self.projectPath = projectPath
        self.releaseNoteInfo = releaseNoteInfo
        self.previousVersion = previousVersion
        self.versionInfo = versionInfo
    }
}

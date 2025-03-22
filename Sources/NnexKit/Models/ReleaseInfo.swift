//
//  ReleaseInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

public struct ReleaseInfo {
    public let binaryPath: String
    public let projectPath: String
    public let releaseNotes: String
    public let versionInfo: ReleaseVersionInfo?
    
    public init(binaryPath: String, projectPath: String, releaseNotes: String, versionInfo: ReleaseVersionInfo?) {
        self.binaryPath = binaryPath
        self.projectPath = projectPath
        self.releaseNotes = releaseNotes
        self.versionInfo = versionInfo
    }
}

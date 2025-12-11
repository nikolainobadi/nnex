//
//  PublishRequest.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Foundation

public struct PublishRequest {
    public let projectName: String
    public let projectPath: String
    public let tap: HomebrewTap
    public let formula: HomebrewFormula
    public let releasePlan: ReleasePlan
    public let notes: ReleaseNotes
    public let buildConfig: BuildConfig
    public let commitMessage: String

    public init(projectName: String, projectPath: String, tap: HomebrewTap, formula: HomebrewFormula, releasePlan: ReleasePlan, notes: ReleaseNotes, buildConfig: BuildConfig, commitMessage: String) {
        self.projectName = projectName
        self.projectPath = projectPath
        self.tap = tap
        self.formula = formula
        self.releasePlan = releasePlan
        self.notes = notes
        self.buildConfig = buildConfig
        self.commitMessage = commitMessage
    }
}


// MARK: - Release Details
public struct ReleasePlan {
    public let previousVersion: String?
    public let next: ReleaseVersionSpecifier

    public init(previousVersion: String?, next: ReleaseVersionSpecifier) {
        self.previousVersion = previousVersion
        self.next = next
    }
}

public enum ReleaseVersionSpecifier {
    case exact(String)
    case increment(ReleaseComponent)
}

public enum ReleaseComponent: String, CaseIterable {
    case major
    case minor
    case patch
}


// MARK: - Release Notes
public enum ReleaseNotes: Sendable {
    case text(String)
    case filePath(String)
}

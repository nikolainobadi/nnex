//
//  AutoVersionHandling.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import Foundation

public protocol AutoVersionHandling {
    /// Detects the current version in the @main ParsableCommand configuration.
    /// - Parameter projectPath: The path to the project directory.
    /// - Returns: The current version string if found, nil otherwise.
    func detectArgumentParserVersion(projectPath: String) throws -> String?

    /// Updates the version in the @main ParsableCommand configuration.
    /// - Parameters:
    ///   - projectPath: The path to the project directory.
    ///   - newVersion: The new version string to set.
    /// - Returns: True if the update was successful, false otherwise.
    func updateArgumentParserVersion(projectPath: String, newVersion: String) throws -> Bool

    /// Determines if the version should be updated based on comparison.
    /// - Parameters:
    ///   - currentVersion: The current version in the source code.
    ///   - releaseVersion: The target release version.
    /// - Returns: True if versions differ and update is needed.
    func shouldUpdateVersion(currentVersion: String, releaseVersion: String) -> Bool
}

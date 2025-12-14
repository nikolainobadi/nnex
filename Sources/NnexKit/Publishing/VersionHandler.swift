//
//  VersionHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Handles version-related operations, such as validation and incrementation.
public enum VersionHandler {
    /// Checks whether a version string follows the semantic versioning pattern (e.g., "1.0.0").
    /// - Parameter version: The version string to validate.
    /// - Returns: A Boolean indicating whether the version string is valid.
    public static func isValidVersionNumber(_ version: String) -> Bool {
        return version.range(of: #"^v?\d+\.\d+\.\d+$"#, options: .regularExpression) != nil
    }

    /// Increments a version number based on the specified version part (major, minor, or patch).
    /// - Parameters:
    ///   - part: The version part to increment.
    ///   - path: The file path associated with the version.
    ///   - previousVersion: The previous version number.
    /// - Returns: The incremented version number as a string.
    /// - Throws: An error if the version number could not be incremented.
    public static func incrementVersion(for part: ReleaseVersionInfo.VersionPart, path: String, previousVersion: String) throws -> String {
        let previousVerisonHasV = previousVersion.hasPrefix("v")
        let cleanedVersion = previousVerisonHasV ? String(previousVersion.dropFirst()) : previousVersion
        var components = cleanedVersion.split(separator: ".").compactMap { Int($0) }

        switch part {
        case .major:
            components[0] += 1
            components[1] = 0
            components[2] = 0
        case .minor:
            components[1] += 1
            components[2] = 0
        case .patch:
            components[2] += 1
        }

        let number = components.map(String.init).joined(separator: ".")
        
        if previousVerisonHasV {
            return "v\(number)"
        }
        
        return number
    }
}

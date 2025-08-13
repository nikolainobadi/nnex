//
//  ReleaseVersionHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import NnexKit

struct ReleaseVersionHandler {
    private let picker: Picker
    private let gitHandler: GitHandler
    
    init(picker: Picker, gitHandler: GitHandler) {
        self.picker = picker
        self.gitHandler = gitHandler
    }
}


// MARK: - Action
extension ReleaseVersionHandler {
    /// Resolves the version information for the release.
    /// - Parameters:
    ///   - versionInfo: Optional version info from command line arguments.
    ///   - projectPath: The path to the project folder.
    /// - Returns: A tuple containing the resolved version information and the previous version (if any).
    /// - Throws: An error if version resolution fails.
    func resolveVersionInfo(versionInfo: ReleaseVersionInfo?, projectPath: String) throws -> (ReleaseVersionInfo, String?) {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: projectPath)
        let resolvedVersionInfo = try versionInfo ?? getVersionInput(previousVersion: previousVersion)
        return (resolvedVersionInfo, previousVersion)
    }
}


// MARK: - Private Methods
private extension ReleaseVersionHandler {
    /// Gets version input from the user or calculates it based on the previous version.
    /// - Parameter previousVersion: The previous version string, if available.
    /// - Returns: A `ReleaseVersionInfo` object representing the new version.
    /// - Throws: An error if the version input is invalid.
    func getVersionInput(previousVersion: String?) throws -> ReleaseVersionInfo {
        var prompt = "\nEnter the version number for this release."

        if let previousVersion {
            prompt.append("\nPrevious release: \(previousVersion.yellow) (To increment, type either \("major".bold), \("minor".bold), or \("patch".bold))")
        } else {
            prompt.append(" (v1.1.0 or 1.1.0)")
        }

        let input = try picker.getRequiredInput(prompt: prompt)

        if let versionPart = ReleaseVersionInfo.VersionPart(string: input) {
            return .increment(versionPart)
        }

        return .version(input)
    }
}
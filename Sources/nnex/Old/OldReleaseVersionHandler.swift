//
//  ReleaseVersionHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import NnexKit
import Foundation

struct OldReleaseVersionHandler {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let autoVersionHandler: any AutoVersionHandling

    init(picker: any NnexPicker, gitHandler: any GitHandler, shell: any NnexShell, fileSystem: any FileSystem, autoVersionHandler: any AutoVersionHandling) {
        self.shell = shell
        self.picker = picker
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
        self.autoVersionHandler = autoVersionHandler
    }
}


// MARK: - Action
extension OldReleaseVersionHandler {
    /// Resolves the version information for the release.
    /// - Parameters:
    ///   - versionInfo: Optional version info from command line arguments.
    ///   - projectPath: The path to the project folder.
    /// - Returns: A tuple containing the resolved version information and the previous version (if any).
    /// - Throws: An error if version resolution fails.
    func resolveVersionInfo(versionInfo: ReleaseVersionInfo?, projectPath: String) throws -> (ReleaseVersionInfo, String?) {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: projectPath)
        let resolvedVersionInfo = try versionInfo ?? getVersionInput(previousVersion: previousVersion)
        
        // Check if we should update the source code version
        try handleAutoVersionUpdate(resolvedVersionInfo: resolvedVersionInfo, projectPath: projectPath)
        
        return (resolvedVersionInfo, previousVersion)
    }
}


// MARK: - Private Methods
private extension OldReleaseVersionHandler {
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
    
    /// Handles automatic version updating in the source code when versions differ.
    /// - Parameters:
    ///   - resolvedVersionInfo: The resolved version information for the release.
    ///   - projectPath: The path to the project folder.
    /// - Throws: An error if version handling fails.
    func handleAutoVersionUpdate(resolvedVersionInfo: ReleaseVersionInfo, projectPath: String) throws {
        // Try to detect current version in the executable
        guard let currentVersion = try autoVersionHandler.detectArgumentParserVersion(projectPath: projectPath) else {
            // No version found in source code, nothing to update
            return
        }
        
        // Get the actual version string from the resolved version info
        let releaseVersionString = try getReleaseVersionString(resolvedVersionInfo: resolvedVersionInfo, projectPath: projectPath)
        
        // Check if versions differ
        guard autoVersionHandler.shouldUpdateVersion(currentVersion: currentVersion, releaseVersion: releaseVersionString) else {
            // Versions are the same, no update needed
            return
        }
        
        // Ask user if they want to update the version
        let prompt = """
        
        Current executable version: \(currentVersion.yellow)
        Release version: \(releaseVersionString.green)
        
        Would you like to update the version in the source code?
        """
        
        guard picker.getPermission(prompt: prompt) else {
            return
        }
        
        // Update the version in source code
        guard try autoVersionHandler.updateArgumentParserVersion(projectPath: projectPath, newVersion: releaseVersionString) else {
            print("Failed to update version in source code.")
            return
        }
        
        // Commit the version update
        try commitVersionUpdate(version: releaseVersionString, projectPath: projectPath)
        
        print("✅ Updated version to \(releaseVersionString.green) and committed changes.")
    }
    
    /// Gets the actual version string from ReleaseVersionInfo.
    /// - Parameters:
    ///   - resolvedVersionInfo: The resolved version information.
    ///   - projectPath: The path to the project folder.
    /// - Returns: The version string.
    /// - Throws: An error if version string cannot be determined.
    func getReleaseVersionString(resolvedVersionInfo: ReleaseVersionInfo, projectPath: String) throws -> String {
        switch resolvedVersionInfo {
        case .version(let versionString):
            return versionString
        case .increment(let versionPart):
            guard let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: projectPath) else {
                throw NnexError.noPreviousVersionToIncrement
            }
            return try VersionHandler.incrementVersion(for: versionPart, path: projectPath, previousVersion: previousVersion)
        }
    }
    
    /// Commits the version update to git.
    /// - Parameters:
    ///   - version: The new version string.
    ///   - projectPath: The path to the project folder.
    /// - Throws: An error if the commit fails.
    func commitVersionUpdate(version: String, projectPath: String) throws {
        let commitMessage = "Update version to \(version)"
        try gitHandler.commitAndPush(message: commitMessage, path: projectPath)
    }
}

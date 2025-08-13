//
//  AutoVersionHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import Files
import Foundation
import NnexKit

struct AutoVersionHandler {
    private let shell: Shell
    
    init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - Public Methods
extension AutoVersionHandler {
    /// Detects the current version in the @main ParsableCommand configuration.
    /// - Parameter projectPath: The path to the project directory.
    /// - Returns: The current version string if found, nil otherwise.
    func detectArgumentParserVersion(projectPath: String) throws -> String? {
        guard let mainFile = try findMainCommandFile(projectPath: projectPath) else {
            return nil
        }
        
        let fileContent = try String(contentsOfFile: mainFile)
        return extractVersionFromContent(fileContent)
    }
    
    /// Updates the version in the @main ParsableCommand configuration.
    /// - Parameters:
    ///   - projectPath: The path to the project directory.
    ///   - newVersion: The new version string to set.
    /// - Returns: True if the update was successful, false otherwise.
    func updateArgumentParserVersion(projectPath: String, newVersion: String) throws -> Bool {
        guard let mainFile = try findMainCommandFile(projectPath: projectPath) else {
            return false
        }
        
        let fileContent = try String(contentsOfFile: mainFile)
        
        // Check if there's a version to update first
        guard extractVersionFromContent(fileContent) != nil else {
            return false
        }
        
        guard let updatedContent = updateVersionInContent(fileContent, newVersion: newVersion) else {
            return false
        }
        
        try updatedContent.write(toFile: mainFile, atomically: true, encoding: .utf8)
        return true
    }
    
    /// Determines if the version should be updated based on comparison.
    /// - Parameters:
    ///   - currentVersion: The current version in the source code.
    ///   - releaseVersion: The target release version.
    /// - Returns: True if versions differ and update is needed.
    func shouldUpdateVersion(currentVersion: String, releaseVersion: String) -> Bool {
        let normalizedCurrent = normalizeVersion(currentVersion)
        let normalizedRelease = normalizeVersion(releaseVersion)
        return normalizedCurrent != normalizedRelease
    }
}


// MARK: - Private Methods
private extension AutoVersionHandler {
    /// Finds the main command file containing @main ParsableCommand.
    /// - Parameter projectPath: The path to the project directory.
    /// - Returns: The file path if found, nil otherwise.
    func findMainCommandFile(projectPath: String) throws -> String? {
        let sourcesPath = "\(projectPath)/Sources"
        
        guard let sourcesFolder = try? Folder(path: sourcesPath) else {
            return nil
        }
        
        // Search for Swift files containing both @main and ParsableCommand
        for file in sourcesFolder.files.recursive {
            guard file.extension == "swift" else { continue }
            
            let content = try file.readAsString()
            if content.contains("@main") && content.contains("ParsableCommand") {
                return file.path
            }
        }
        
        return nil
    }
    
    /// Extracts version from file content using regex.
    /// - Parameter content: The file content to search.
    /// - Returns: The version string if found.
    func extractVersionFromContent(_ content: String) -> String? {
        // Look for version: "x.x.x" pattern in CommandConfiguration
        let pattern = #"version:\s*"([^"]+)""#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: content.utf16.count)
        guard let match = regex.firstMatch(in: content, options: [], range: range) else {
            return nil
        }
        
        guard let versionRange = Range(match.range(at: 1), in: content) else {
            return nil
        }
        
        return String(content[versionRange])
    }
    
    /// Updates version in file content.
    /// - Parameters:
    ///   - content: The original file content.
    ///   - newVersion: The new version to set.
    /// - Returns: Updated content if successful, nil otherwise.
    func updateVersionInContent(_ content: String, newVersion: String) -> String? {
        let pattern = #"(version:\s*)"([^"]+)""#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: content.utf16.count)
        let replacement = "$1\"\(newVersion)\""
        
        return regex.stringByReplacingMatches(
            in: content,
            options: [],
            range: range,
            withTemplate: replacement
        )
    }
    
    /// Normalizes version strings for comparison (removes 'v' prefix if present).
    /// - Parameter version: The version string to normalize.
    /// - Returns: Normalized version string.
    func normalizeVersion(_ version: String) -> String {
        return version.hasPrefix("v") ? String(version.dropFirst()) : version
    }
}
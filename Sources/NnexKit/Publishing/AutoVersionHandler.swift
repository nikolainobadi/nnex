//
//  AutoVersionHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import Foundation

public struct AutoVersionHandler {
    private let shell: any NnexShell
    private let fileSystem: any FileSystem

    public init(shell: any NnexShell, fileSystem: any FileSystem) {
        self.shell = shell
        self.fileSystem = fileSystem
    }
}


// MARK: - Public Methods
public extension AutoVersionHandler {
    /// Detects the current version in the @main ParsableCommand configuration.
    /// - Parameter projectPath: The path to the project directory.
    /// - Returns: The current version string if found, nil otherwise.
    func detectArgumentParserVersion(projectPath: String) throws -> String? {
        guard let mainFile = try findMainCommandFile(projectPath: projectPath) else {
            return nil
        }

        let fileContent = try fileSystem.readFile(at: mainFile)
        
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

        let fileContent = try fileSystem.readFile(at: mainFile)

        // Check if there's a version to update first
        guard extractVersionFromContent(fileContent) != nil else {
            return false
        }

        // Force normalized "1.2.3" format (no "v" prefix)
        let forced = normalizeVersion(newVersion)

        guard let updatedContent = updateVersionInContent(fileContent, newVersion: forced) else {
            return false
        }

        try fileSystem.writeFile(at: mainFile, contents: updatedContent)
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
        guard let sourcesFolder = try? fileSystem.directory(at: sourcesPath) else { return nil }

        let pattern = try NSRegularExpression(
            pattern: #"@main\s+(struct|class|enum)\s+\w+\s*:\s*[^{}]*\bParsableCommand\b"#,
            options: [.dotMatchesLineSeparators]
        )

        let swiftFiles = try sourcesFolder.findFiles(withExtension: "swift", recursive: true)

        for filePath in swiftFiles {
            let raw = try fileSystem.readFile(at: filePath)
            let code = strippedCode(raw)
            let range = NSRange(code.startIndex..<code.endIndex, in: code)
            if pattern.firstMatch(in: code, options: [], range: range) != nil {
                return filePath
            }
        }

        return nil
    }
    
    /// Extracts version from file content using regex.
    /// - Parameter content: The file content to search.
    /// - Returns: The version string if found.
    func extractVersionFromContent(_ content: String) -> String? {
        // Look for version: "0.8.6" or version: "v0.8.6"
        let pattern = #"version\s*:\s*"([^"]+)""#
        
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
        
        let raw = String(content[versionRange])
        return normalizeVersion(raw)
    }
    
    /// Updates version in file content.
    /// - Parameters:
    ///   - content: The original file content.
    ///   - newVersion: The new version to set.
    /// - Returns: Updated content if successful, nil otherwise.
    func updateVersionInContent(_ content: String, newVersion: String) -> String? {
        let pattern = #"version\s*:\s*"([^"]+)""#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        // Force always-writing the strict format:
        // version: "1.2.3"
        let forcedLine = #"version: "\#(newVersion)""#
        
        let range = NSRange(location: 0, length: content.utf16.count)
        
        return regex.stringByReplacingMatches(
            in: content,
            options: [],
            range: range,
            withTemplate: forcedLine
        )
    }
    
    /// Normalizes version strings for comparison (removes 'v' prefix if present).
    /// - Parameter version: The version string to normalize.
    /// - Returns: Normalized version string.
    func normalizeVersion(_ version: String) -> String {
        let trimmed = version.trimmingCharacters(in: .whitespaces)
        if trimmed.lowercased().hasPrefix("v") {
            return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return trimmed
    }
    
    func strippedCode(_ s: String) -> String {
        var out = ""
        var i = s.startIndex
        var inSL = false, inML = false, inStr = false, inRawStr = false
        while i < s.endIndex {
            let c = s[i]
            let nxt = s.index(after: i)
            if inStr {
                if c == "\"" && !inRawStr { inStr = false }
                i = nxt
                continue
            }
            if inRawStr {
                if c == "\"" { inRawStr = false }
                i = nxt
                continue
            }
            if inSL {
                if c == "\n" { inSL = false; out.append(c) }
                i = nxt
                continue
            }
            if inML {
                if c == "*" && nxt < s.endIndex && s[nxt] == "/" { inML = false; i = s.index(after: nxt) ; continue }
                i = nxt
                continue
            }
            if c == "\"" {
                inStr = true
                i = nxt
                continue
            }
            if c == "#" && nxt < s.endIndex && s[nxt] == "\"" {
                inRawStr = true
                i = s.index(after: nxt)
                continue
            }
            if c == "/" && nxt < s.endIndex {
                if s[nxt] == "/" { inSL = true; i = s.index(after: nxt); continue }
                if s[nxt] == "*" { inML = true; i = s.index(after: nxt); continue }
            }
            out.append(c)
            i = nxt
        }
        return out
    }
}

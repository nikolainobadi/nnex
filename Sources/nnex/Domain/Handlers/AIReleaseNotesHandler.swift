//
//  AIReleaseNotesHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import Foundation
import GitCommandGen
import NnShellKit
import NnexKit

/// Handles generation of AI-powered release notes using Claude Code CLI.
struct AIReleaseNotesHandler {
    private let projectName: String
    private let shell: any Shell
    private let picker: NnexPicker
    private let changeLogLoader: ChangeLogInfoLoader
    private let fileUtility: ReleaseNotesFileUtility
    
    /// Initializes a new AIReleaseNotesHandler instance.
    /// - Parameters:
    ///   - projectName: The name of the project for generating release notes.
    ///   - shell: The shell instance for executing commands.
    ///   - picker: The picker for user interactions.
    ///   - fileUtility: The file utility for creating and validating files.
    init(projectName: String, shell: any Shell, picker: NnexPicker, fileUtility: ReleaseNotesFileUtility) {
        self.projectName = projectName
        self.shell = shell
        self.picker = picker
        self.changeLogLoader = ChangeLogInfoLoader(shell: shell)
        self.fileUtility = fileUtility
    }
}


// MARK: - Methods
extension AIReleaseNotesHandler {
    /// Generates AI-powered release notes for a given version.
    /// - Parameters:
    ///   - releaseNumber: The version number for the release.
    ///   - projectPath: The path to the project directory.
    /// - Returns: A ReleaseNoteInfo instance containing the release notes.
    /// - Throws: An error if generation fails.
    func generateReleaseNotes(releaseNumber: String, projectPath: String) throws -> ReleaseNoteInfo {
        if let existingNotes = try checkExistingChangelog(for: releaseNumber, projectPath: projectPath) {
            return .init(content: existingNotes, isFromFile: false)
        }
        
        let changeLogInfo = try changeLogLoader.loadChangeLogInfo()
        let releaseNotesFile = try fileUtility.createVersionedNoteFile(projectName: projectName, version: releaseNumber)
        
        try generateWithClaude(
            changeLogInfo: changeLogInfo,
            releaseNumber: releaseNumber,
            outputFile: releaseNotesFile.path
        )
        
        return try fileUtility.validateAndConfirmNoteFile(releaseNotesFile)
    }
}


// MARK: - Private Methods
private extension AIReleaseNotesHandler {
    func checkExistingChangelog(for version: String, projectPath: String) throws -> String? {
        let changelogPath = "\(projectPath)/CHANGELOG.md"
        
        guard FileManager.default.fileExists(atPath: changelogPath) else {
            return nil
        }
        
        let content = try String(contentsOfFile: changelogPath, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        let versionHeader = "## [\(version)]"
        guard let startIndex = lines.firstIndex(where: { $0.hasPrefix(versionHeader) }) else {
            return nil
        }
        
        var endIndex = lines.count
        for i in (startIndex + 1)..<lines.count {
            if lines[i].hasPrefix("## [") {
                endIndex = i
                break
            }
        }
        
        let sectionLines = Array(lines[(startIndex + 1)..<endIndex])
        let sectionContent = sectionLines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        
        return sectionContent.isEmpty ? nil : sectionContent
    }
    
    func generateWithClaude(changeLogInfo: ChangeLogInfo, releaseNumber: String, outputFile: String) throws {
        let prompt = formatPromptForClaude(changeLogInfo: changeLogInfo, releaseNumber: releaseNumber)
        let tempPromptPath = "/tmp/nnex-release-prompt-\(UUID().uuidString).md"
        
        try prompt.write(toFile: tempPromptPath, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(atPath: tempPromptPath)
        }
        
        let claudeCommand = "claude code edit \"\(outputFile)\" --prompt \"$(cat '\(tempPromptPath)')\""
        
        do {
            _ = try shell.bash(claudeCommand)
        } catch {
            throw AIChangeLogError.fileOperationFailed("Failed to generate release notes with Claude: \(error.localizedDescription)")
        }
    }
    
    func formatPromptForClaude(changeLogInfo: ChangeLogInfo, releaseNumber: String) -> String {
        let commitsSection = changeLogInfo.commits
            .map { "- \($0)" }
            .joined(separator: "\n")
        
        let filesSection = changeLogInfo.filesChanged
            .map { "- [\($0.status)] \($0.filename)" }
            .joined(separator: "\n")
        
        let diffPreview = String(changeLogInfo.compactDiff.prefix(5000))
        
        return """
        Generate release notes for version \(releaseNumber) of \(projectName) in CHANGELOG.md format.
        
        Use this exact format:
        ### Added
        - New features added
        
        ### Changed
        - Changes in existing functionality
        
        ### Fixed
        - Bug fixes
        
        ### Removed
        - Features removed
        
        Only include sections that have relevant changes. Write concise, user-facing descriptions.
        
        ## Git History Context:
        
        Previous Version: \(changeLogInfo.previousTag)
        
        Commits:
        \(commitsSection)
        
        Files Changed:
        \(filesSection)
        
        Statistics:
        \(changeLogInfo.changeStats)
        
        Detailed Changes:
        \(diffPreview)
        
        Based on the above git history, generate professional release notes focusing on user-facing changes.
        """
    }
}

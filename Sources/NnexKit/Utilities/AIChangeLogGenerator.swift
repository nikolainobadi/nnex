//
//  AIChangeLogGenerator.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files
import Foundation
import GitCommandGen
import NnShellKit

/// Generates or updates CHANGELOG.md files using Claude AI based on git history.
public struct AIChangeLogGenerator {
    private let shell: any Shell
    private let changeLogLoader: ChangeLogInfoLoader

    /// Initializes a new AIChangeLogGenerator instance.
    /// - Parameter shell: The shell instance for executing commands.
    public init(shell: any Shell) {
        self.shell = shell
        self.changeLogLoader = ChangeLogInfoLoader(shell: shell)
    }
}


// MARK: - Public Methods
public extension AIChangeLogGenerator {
    /// Generates or updates a CHANGELOG.md file using Claude AI.
    /// - Parameters:
    ///   - projectPath: The path to the project directory.
    ///   - version: Optional version number for the new changelog entry.
    ///   - dryRun: If true, prints the generated section and does not modify files.
    /// - Throws: An error if the generation fails.
    func generateChangeLog(projectPath: String, version: String? = nil, dryRun: Bool = false) throws {
        try claudeVerification()

        let projectFolder = try Folder(path: projectPath)
        let changeLogPath = projectFolder.path + "/CHANGELOG.md"

        if FileManager.default.fileExists(atPath: changeLogPath) {
            try updateExistingChangeLog(projectPath: projectPath, changeLogPath: changeLogPath, version: version, dryRun: dryRun)
        } else {
            try createNewChangeLog(projectPath: projectPath, changeLogPath: changeLogPath, version: version, dryRun: dryRun)
        }
    }

    /// Verifies if the Claude CLI is installed and provides installation instructions if not.
    /// - Throws: An error if Claude CLI is not found.
    func claudeVerification() throws {
        do {
            let result = try shell.bash("which claude")
            if result.contains("not found") || result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw AIChangeLogError.missingClaudeCLI
            }
        } catch {
            throw AIChangeLogError.missingClaudeCLI
        }
    }
}


// MARK: - Private Methods
private extension AIChangeLogGenerator {
    /// Reads the changelog guidelines from the project or global locations if available.
    /// Search order:
    /// 1) <projectPath>/docs/changelog-guidelines.md
    /// 2) $NNEX_CHANGELOG_GUIDELINES (path)
    /// 3) ~/.claude/guidelines/changelog-guidelines.md
    /// - Parameter projectPath: The path to the project directory.
    /// - Returns: The content of the guidelines file, or nil if not found.
    func readChangelogGuidelines(projectPath: String) -> String? {
        let projectGuidelines = projectPath + "/docs/changelog-guidelines.md"
        if FileManager.default.fileExists(atPath: projectGuidelines),
           let contents = try? String(contentsOfFile: projectGuidelines) {
            return contents
        }

        if let envPath = ProcessInfo.processInfo.environment["NNEX_CHANGELOG_GUIDELINES"],
           !envPath.isEmpty,
           FileManager.default.fileExists(atPath: envPath),
           let contents = try? String(contentsOfFile: envPath) {
            return contents
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let defaultGlobal = home + "/.claude/guidelines/changelog-guidelines.md"
        if FileManager.default.fileExists(atPath: defaultGlobal),
           let contents = try? String(contentsOfFile: defaultGlobal) {
            return contents
        }

        return nil
    }
    
    /// Updates an existing CHANGELOG.md file with a new section.
    /// - Parameters:
    ///   - projectPath: The path to the project directory.
    ///   - changeLogPath: The path to the existing CHANGELOG.md file.
    ///   - version: Optional version number for the new changelog entry.
    ///   - dryRun: If true, prints the updated file without writing to disk.
    /// - Throws: An error if the update fails.
    func updateExistingChangeLog(projectPath: String, changeLogPath: String, version: String?, dryRun: Bool) throws {
        let changeLogInfo = try changeLogLoader.loadChangeLogInfo()
        let existingContent = try String(contentsOfFile: changeLogPath)
        let guidelines = readChangelogGuidelines(projectPath: projectPath)

        // Ask Claude for the complete updated file content
        let prompt = buildCompleteFilePrompt(
            changeLogInfo: changeLogInfo,
            version: version,
            guidelines: guidelines,
            existingContent: existingContent
        )

        let updatedContent = try executeClaudeCommand(prompt: prompt, projectPath: projectPath).trimmingCharacters(in: .whitespacesAndNewlines)
        if updatedContent.isEmpty { throw AIChangeLogError.emptyClaudeResponse }

        if dryRun {
            print("----- Proposed CHANGELOG.md -----")
            print(updatedContent)
            print("----- End file -----")
            return
        }

        try updatedContent.write(toFile: changeLogPath, atomically: true, encoding: .utf8)
    }

    /// Creates a new CHANGELOG.md file with the initial section.
    /// - Parameters:
    ///   - projectPath: The path to the project directory.
    ///   - changeLogPath: The path where the new CHANGELOG.md file should be created.
    ///   - version: Optional version number for the initial changelog entry.
    ///   - dryRun: If true, prints the new file content without writing to disk.
    /// - Throws: An error if the creation fails.
    func createNewChangeLog(projectPath: String, changeLogPath: String, version: String?, dryRun: Bool) throws {
        let changeLogInfo = try changeLogLoader.loadChangeLogInfo()
        let guidelines = readChangelogGuidelines(projectPath: projectPath)

        // Ask Claude for the complete new CHANGELOG.md file
        let newContent = try executeClaudeCommand(
            prompt: buildCompleteFilePrompt(changeLogInfo: changeLogInfo, version: version, guidelines: guidelines),
            projectPath: projectPath
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        if newContent.isEmpty { throw AIChangeLogError.emptyClaudeResponse }

        if dryRun {
            print("----- Proposed CHANGELOG.md -----")
            print(newContent)
            print("----- End file -----")
            return
        }

        try newContent.write(toFile: changeLogPath, atomically: true, encoding: .utf8)
    }

    /// Executes a Claude CLI command with the given prompt and project context.
    /// - Parameters:
    ///   - prompt: The prompt to send to Claude.
    ///   - projectPath: The path to the project directory for context.
    /// - Returns: The response from Claude.
    /// - Throws: An error if the command fails.
    func executeClaudeCommand(prompt: String, projectPath: String) throws -> String {
        // Create a temporary file for the prompt to handle multiline content properly
        let tempFile = try createTempPromptFile(content: prompt)
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        // Use file input with project directory context
        let command = "claude --file \"\(tempFile)\" --add-dir \"\(projectPath)\""
        let result = try shell.bash(command)

        if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AIChangeLogError.emptyClaudeResponse
        }

        return result
    }

    /// Creates a temporary file containing the prompt content.
    /// - Parameter content: The prompt content to write to the temporary file.
    /// - Returns: The path to the temporary file.
    /// - Throws: An error if file creation fails.
    func createTempPromptFile(content: String) throws -> String {
        let tempDir = NSTemporaryDirectory()
        let tempFile = tempDir + "claude_prompt_\(UUID().uuidString).txt"
        try content.write(toFile: tempFile, atomically: true, encoding: .utf8)
        return tempFile
    }

    // MARK: Prompts

    /// Builds a prompt that requests the complete updated CHANGELOG.md file content.
    /// - Parameters:
    ///   - changeLogInfo: The changelog information from git.
    ///   - version: Optional version number; if nil, generate an `[Unreleased]` section.
    ///   - guidelines: Optional changelog guidelines content.
    ///   - existingContent: Optional existing CHANGELOG.md content for updates.
    /// - Returns: A formatted prompt for Claude.
    func buildCompleteFilePrompt(changeLogInfo: ChangeLogInfo, version: String?, guidelines: String?, existingContent: String? = nil) -> String {
        let versionText = version?.trimmingCharacters(in: .whitespacesAndNewlines)
        let date = formatDateForChangelog()
        let contextSection = formatChangeLogContext(changeLogInfo)

        let guidelinesSection = guidelines.map { """
        CHANGELOG GUIDELINES TO FOLLOW:
        \($0)
        """ } ?? ""

        let existingSection = existingContent.map { """
        
        EXISTING CHANGELOG.MD CONTENT:
        \($0)
        """ } ?? ""

        let headerDirective: String
        if let ver = versionText, !ver.isEmpty {
            headerDirective = "Update the CHANGELOG.md file by adding a Keep a Changelog section for version \(ver) released on \(date)."
        } else {
            headerDirective = "Update the CHANGELOG.md file by adding a Keep a Changelog section for [Unreleased]."
        }

        return """
        \(headerDirective)\(existingSection)
        \(guidelinesSection)

        \(contextSection)

        Rules:
        - User-facing changes only (CLI commands, flags, defaults, behavior)
        - Group under: Added, Changed, Fixed, Removed, Deprecated, Security
        - Mark breaking changes with **Breaking** and include a 1-line migration tip
        - Imperative mood; concise, single-sentence bullets
        - Keep a Changelog format with proper headers and structure
        - OUTPUT: The complete updated CHANGELOG.md file contents. Include all existing content and add the new section appropriately positioned.

        """
    }

    /// Formats the changelog context information for use in Claude prompts.
    /// - Parameter changeLogInfo: The changelog information to format.
    /// - Returns: A formatted string containing all the context.
    func formatChangeLogContext(_ changeLogInfo: ChangeLogInfo) -> String {
        let commits = changeLogInfo.commits.joined(separator: "\n")
        let filesChanged = changeLogInfo.filesChanged.map { "\($0.status)\t\(_escapeTabsAndNewlines($0.filename))" }.joined(separator: "\n")

        return """
        GIT CONTEXT (changes since \(changeLogInfo.previousTag)):

        ### Commits
        \(commits)

        ### Files Changed (name-status)
        \(filesChanged)

        ### Change Stats
        \(changeLogInfo.changeStats)

        ### Compact Diff (unified=0, function-context, capped)
        \(changeLogInfo.compactDiff)
        """
    }


    /// Formats the current date in YYYY-MM-DD format for changelog entries.
    /// - Returns: A date string in ISO 8601 format.
    func formatDateForChangelog() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: Date())
    }

    /// Escape tabs and newlines inside file names to keep the prompt layout stable.
    func _escapeTabsAndNewlines(_ s: String) -> String {
        s.replacingOccurrences(of: "\t", with: "\\t")
         .replacingOccurrences(of: "\n", with: "\\n")
    }
}

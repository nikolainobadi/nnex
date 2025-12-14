//
//  VersionNumberController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit

struct VersionNumberController {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let versionService: any VersionNumberService
    
    init(shell: any NnexShell, picker: any NnexPicker, gitHandler: any GitHandler, fileSystem: any FileSystem, versionService: any VersionNumberService) {
        self.shell = shell
        self.picker = picker
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
        self.versionService = versionService
    }
}


// MARK: - Select Version Number
extension VersionNumberController {
    func selectNextVersionNumber(projectPath: String, versionInfo: ReleaseVersionInfo?) throws -> String {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: projectPath)
        let versionInput = try versionInfo ?? getVersionInput(previousVersion: previousVersion)
        let releaseVersionString = try getReleaseVersionString(resolvedVersionInfo: versionInput, projectPath: projectPath)
        
        try handleAutoVersionUpdate(releaseVersionString: releaseVersionString, projectPath: projectPath)
        
        return releaseVersionString
    }
}


// MARK: - Private Methods
private extension VersionNumberController {
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
    
    func handleAutoVersionUpdate(releaseVersionString: String, projectPath: String) throws {
        guard
            let currentVersion = try versionService.detectArgumentParserVersion(projectPath: projectPath),
            versionService.shouldUpdateVersion(currentVersion: currentVersion, releaseVersion: releaseVersionString)
        else {
            return
        }
        
        let prompt = """
        
        Current executable version: \(currentVersion.yellow)
        Release version: \(releaseVersionString.green)
        
        Would you like to update the version in the source code?
        """
        
        guard picker.getPermission(prompt: prompt) else {
            return
        }
        
        // Update the version in source code
        guard try versionService.updateArgumentParserVersion(projectPath: projectPath, newVersion: releaseVersionString) else {
            print("Failed to update version in source code.")
            return
        }
        
        // Commit the version update
        try commitVersionUpdate(version: releaseVersionString, projectPath: projectPath)
        
        print("✅ Updated version to \(releaseVersionString.green) and committed changes.")
    }
    
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
    
    func commitVersionUpdate(version: String, projectPath: String) throws {
        let commitMessage = "Update version to \(version)"
        try gitHandler.commitAndPush(message: commitMessage, path: projectPath)
    }
}


// MARK: - Dependencies
protocol VersionNumberService {
    func detectArgumentParserVersion(projectPath: String) throws -> String?
    func shouldUpdateVersion(currentVersion: String, releaseVersion: String) -> Bool
    func updateArgumentParserVersion(projectPath: String, newVersion: String) throws -> Bool
}

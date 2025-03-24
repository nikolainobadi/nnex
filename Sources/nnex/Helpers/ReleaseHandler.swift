//
//  ReleaseHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import NnexKit
import Foundation
import GitCommandGen

struct ReleaseHandler {
    private let picker: Picker
    private let gitHandler: GitHandler
    
    init(picker: Picker, gitHandler: GitHandler) {
        self.picker = picker
        self.gitHandler = gitHandler
    }
}


// MARK: - Action
extension ReleaseHandler {
    func uploadRelease(folder: Folder, binaryInfo: BinaryInfo, versionInfo: ReleaseVersionInfo?, releaseNotesSource: ReleaseNotesSource) throws -> String {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: folder.path)
        let versionInfo = try versionInfo ?? getVersionInput(previousVersion: previousVersion)
        let releaseNoteInfo = try getReleaseNoteInfo(projectName: folder.name, releaseNotesSource: releaseNotesSource)
        let releaseInfo = ReleaseInfo(binaryPath: binaryInfo.path, projectPath: folder.path, releaseNoteInfo: releaseNoteInfo, previousVersion: previousVersion, versionInfo: versionInfo)
        let store = ReleaseStore(gitHandler: gitHandler)
        let (assetURL, versionNumber) = try store.uploadRelease(info: releaseInfo)
        
        print("GitHub release \(versionNumber) created and binary uploaded to \(assetURL)")
        return assetURL
    }
}


// MARK: - Private Methods
private extension ReleaseHandler {
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
    
    func getReleaseNoteInfo(projectName: String, releaseNotesSource: ReleaseNotesSource) throws -> ReleaseNoteInfo {
        if let notesFile = releaseNotesSource.notesFile {
            return .init(content: notesFile, isFromFile: true)
        }
        
        if let notes = releaseNotesSource.notes {
            return .init(content: notes, isFromFile: false)
        }
        
        return try ReleaseNotesHandler(picker: picker, projectName: projectName).getReleaseNoteInfo()
    }
}

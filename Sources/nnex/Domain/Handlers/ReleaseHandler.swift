//
//  ReleaseHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import Foundation
import NnexKit
import GitCommandGen
import NnShellKit

struct ReleaseHandler {
    private let picker: NnexPicker
    private let gitHandler: GitHandler
    private let trashHandler: TrashHandler
    
    init(picker: NnexPicker, gitHandler: GitHandler, trashHandler: TrashHandler) {
        self.picker = picker
        self.gitHandler = gitHandler
        self.trashHandler = trashHandler
    }
}

// MARK: - Action
extension ReleaseHandler {
    func uploadRelease(folder: Folder, archivedBinaries: [ArchivedBinary], versionInfo: ReleaseVersionInfo, previousVersion: String?, releaseNotesSource: ReleaseNotesSource) throws -> (assetURLs: [String], versionNumber: String) {
        let releaseNumber = extractVersionString(from: versionInfo)
        let noteInfo = try getReleaseNoteInfo(projectName: folder.name, releaseNotesSource: releaseNotesSource, releaseNumber: releaseNumber, projectPath: folder.path)
        let store = ReleaseStore(gitHandler: gitHandler)

        let releaseInfo = ReleaseInfo(
            projectPath: folder.path,
            releaseNoteInfo: noteInfo,
            previousVersion: previousVersion,
            versionInfo: versionInfo
        )

        let (assetURLs, versionNumber) = try store.uploadRelease(info: releaseInfo, archivedBinaries: archivedBinaries)
        try maybeTrashReleaseNotes(noteInfo)
        let primaryAssetURL = assetURLs.first ?? ""

        if archivedBinaries.count == 1 {
            print("GitHub release \(versionNumber) created and binary uploaded to \(primaryAssetURL)")
        } else {
            print("GitHub release \(versionNumber) created and \(archivedBinaries.count) binaries uploaded. First asset at \(primaryAssetURL)")
            if assetURLs.count > 1 {
                print("Additional assets:")
                for (index, url) in assetURLs.dropFirst().enumerated() {
                    print("  Asset \(index + 2): \(url)")
                }
            }
        }

        return (assetURLs, versionNumber)
    }
}

// MARK: - Private
private extension ReleaseHandler {
    func getReleaseNoteInfo(projectName: String, releaseNotesSource: ReleaseNotesSource, releaseNumber: String, projectPath: String) throws -> ReleaseNoteInfo {
        if let notesFile = releaseNotesSource.notesFile {
            return .init(content: notesFile, isFromFile: true)
        }
        if let notes = releaseNotesSource.notes {
            return .init(content: notes, isFromFile: false)
        }
        return try ReleaseNotesHandler(picker: picker, projectName: projectName).getReleaseNoteInfo()
    }
    
    func maybeTrashReleaseNotes(_ info: ReleaseNoteInfo) throws {
        if info.isFromFile, picker.getPermission(prompt: "Would you like to move your release notes file to the trash?") {
            try trashHandler.moveToTrash(at: info.content)
        }
    }
    
    func extractVersionString(from versionInfo: ReleaseVersionInfo) -> String {
        switch versionInfo {
        case .version(let versionString):
            return versionString.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        case .increment:
            // For increment case, we'll need to resolve this at a higher level
            // For now, return a placeholder - the actual version will be resolved later
            return "0.0.0"
        }
    }
}

// MARK: - Dependencies
protocol TrashHandler {
    func moveToTrash(at path: String) throws
}

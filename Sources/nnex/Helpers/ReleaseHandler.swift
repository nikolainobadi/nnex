//
//  ReleaseHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import NnexKit
import GitCommandGen

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
    func uploadRelease(folder: Folder, archivedBinaries: [ArchivedBinary], versionInfo: ReleaseVersionInfo, previousVersion: String?, releaseNotesSource: ReleaseNotesSource) throws -> [String] {
        let noteInfo = try getReleaseNoteInfo(projectName: folder.name, releaseNotesSource: releaseNotesSource)
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
        
        return assetURLs
    }
}

// MARK: - Private
private extension ReleaseHandler {
    func getReleaseNoteInfo(projectName: String, releaseNotesSource: ReleaseNotesSource) throws -> ReleaseNoteInfo {
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
}

// MARK: - Dependencies
protocol TrashHandler {
    func moveToTrash(at path: String) throws
}

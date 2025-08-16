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
    private let picker: NnexPicker
    private let gitHandler: GitHandler
    
    init(picker: NnexPicker, gitHandler: GitHandler) {
        self.picker = picker
        self.gitHandler = gitHandler
    }
}


// MARK: - Action
extension ReleaseHandler {
    func uploadRelease(folder: Folder, binaryInfo: BinaryInfo, versionInfo: ReleaseVersionInfo, previousVersion: String?, releaseNotesSource: ReleaseNotesSource) throws -> String {
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

//
//  DryRunPublishGitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/14/25.
//

import NnexKit
import GitShellKit

struct DryRunPublishGitHandler {
    private let gitHandler: any GitHandler
    
    init(gitHandler: any GitHandler) {
        self.gitHandler = gitHandler
    }
}


// MARK: - GitHandler
extension DryRunPublishGitHandler: GitHandler {
    func ghVerification() throws {
        return try gitHandler.ghVerification()
    }
    
    func gitInit(path: String) throws {
        return try gitHandler.gitInit(path: path)
    }
    
    func getRemoteURL(path: String) throws -> String {
        return try gitHandler.getRemoteURL(path: path)
    }
    
    func commitAndPush(message: String, path: String) throws {
        print("prepering to commit at \(path.underline), message: \(message.yellow)")
    }
    
    func getPreviousReleaseVersion(path: String) throws -> String {
        return try gitHandler.getPreviousReleaseVersion(path: path)
    }
    
    func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String {
        return try gitHandler.remoteRepoInit(tapName: tapName, path: path, projectDetails: projectDetails, visibility: visibility)
    }
    
    func createNewRelease(version: String, archivedBinaries: [ArchivedBinary], releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> [String] {
        print(
            """
            
            \("New Release Details".underline)
            version: \(version)
            archivedBinaryCount: \(archivedBinaries.count)
            projectFolderPath: \(path)
            \(releaseNoteInfo.detailText)
            
            """
        )
        return []
    }
}


// MARK: - Extension Dependencies
private extension ReleaseNoteInfo {
    var detailText: String {
        if isFromFile {
            return "releaseNotesFilePath: \(content)"
        }
        
        return "releaseNotes: \(content)"
    }
}

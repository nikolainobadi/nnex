//
//  File.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit

struct PublishDelegateAdapter {
    private let artifactController: ArtifactController
    private let versionController: VersionNumberController
    private let releaseController: GithubReleaseController
    private let publishController: FormulaPublishController
    
    init(versionController: VersionNumberController, artifactController: ArtifactController, releaseController: GithubReleaseController, publishController: FormulaPublishController) {
        self.versionController = versionController
        self.artifactController = artifactController
        self.releaseController = releaseController
        self.publishController = publishController
    }
}


// MARK: - PublishDelegate
extension PublishDelegateAdapter: PublishDelegate {
    func resolveNextVersionNumber(projectPath: String, versionInfo: ReleaseVersionInfo?) throws -> String {
        return try versionController.selectNextVersionNumber(projectPath: projectPath, versionInfo: versionInfo)
    }
    
    func buildArtifacts(projectFolder folder: any Directory, buildType: BuildType, versionNumber: String) throws -> ReleaseArtifact {
        return try artifactController.buildArtifacts(projectFolder: folder, buildType: buildType, versionNumber: versionNumber)
    }
    
    func uploadRelease(version: String, assets: [ArchivedBinary], notes: String?, notesFilePath: String?, projectFolder: any Directory) throws -> [String] {
        return try releaseController.uploadRelease(version: version, assets: assets, notes: notes, notesFilePath: notesFilePath, projectFolder: projectFolder)
    }
    
    func publishFormula(projectFolder: any Directory, info: FormulaPublishInfo, commitMessage: String?) throws {
        try publishController.publishFormula(projectFolder: projectFolder, info: info, commitMessage: commitMessage)
    }
}

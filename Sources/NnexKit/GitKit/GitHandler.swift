//
//  GitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import GitShellKit

public protocol GitHandler {
    func ghVerification() throws
    func gitInit(path: String) throws
    func getRemoteURL(path: String) throws -> String
    func commitAndPush(message: String, path: String) throws
    func getPreviousReleaseVersion(path: String) throws -> String
    func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String
    func createNewRelease(version: String, binaryPath: String, releaseNotes: String, path: String) throws -> String
}

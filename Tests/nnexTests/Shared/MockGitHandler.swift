//
//  MockGitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import GitShellKit
@testable import nnex

final class MockGitHandler {
    private let remoteURL: String
    private let previousVersion: String
    private let assetURL: String
    
    init(remoteURL: String = "", previousVersion: String = "", assetURL: String = "") {
        self.remoteURL = remoteURL
        self.previousVersion = previousVersion
        self.assetURL = assetURL
    }
}


// MARK: - Delegate
extension MockGitHandler: GitHandler {
    func commitAndPush(message: String, path: String) throws {
        // TODO: - 
    }
    
    func gitInit(path: String) throws {
        // TODO: -
    }
    
    func getRemoteURL(path: String) throws -> String {
        return remoteURL
    }
    
    func getPreviousReleaseVersion(path: String) throws -> String {
        return previousVersion
    }
    
    func remoteRepoInit(tapName: String, path: String, projectDetails: String?, visibility: RepoVisibility) throws -> String {
        return remoteURL
    }
    
    func createNewRelease(version: String, binaryPath: String, releaseNotes: String, path: String) throws -> String {
        return assetURL
    }
}

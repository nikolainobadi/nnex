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
    private let ghIsInstalled: Bool
    private(set) var message: String?
    
    init(remoteURL: String = "", previousVersion: String = "", assetURL: String = "", ghIsInstalled: Bool = true) {
        self.remoteURL = remoteURL
        self.previousVersion = previousVersion
        self.assetURL = assetURL
        self.ghIsInstalled = ghIsInstalled
    }
}


// MARK: - Delegate
extension MockGitHandler: GitHandler {
    func ghVerification() throws {
        if !ghIsInstalled {
            throw NnexError.missingGitHubCLI
        }
    }
    
    func commitAndPush(message: String, path: String) throws {
        self.message = message
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

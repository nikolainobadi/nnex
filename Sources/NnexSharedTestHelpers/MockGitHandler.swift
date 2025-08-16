//
//  MockGitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import NnexKit
import Foundation
import GitShellKit

public final class MockGitHandler {
    private let assetURL: String
    private let throwError: Bool
    private let remoteURL: String
    private let ghIsInstalled: Bool
    private let previousVersion: String
    
    private(set) public var message: String?
    private(set) public var gitInitPath: String?
    private(set) public var remoteTapName: String?
    private(set) public var remoteTapPath: String?
    private(set) public var releaseVersion: String?
    private(set) public var releaseNoteInfo: ReleaseNoteInfo?
    
    public init(remoteURL: String = "", previousVersion: String = "", assetURL: String = "", ghIsInstalled: Bool = true, throwError: Bool = false) {
        self.remoteURL = remoteURL
        self.previousVersion = previousVersion
        self.assetURL = assetURL
        self.ghIsInstalled = ghIsInstalled
        self.throwError = throwError
    }
}


// MARK: - Delegate
extension MockGitHandler: GitHandler {
    public func ghVerification() throws {
        if throwError { throw NSError(domain: "Test", code: 0) }
        if !ghIsInstalled {
            throw NnexError.missingGitHubCLI
        }
    }
    
    public func commitAndPush(message: String, path: String) throws {
        if throwError { throw NSError(domain: "Test", code: 0) }
        self.message = message
    }
    
    public func gitInit(path: String) throws {
        if throwError { throw NSError(domain: "Test", code: 0) }
        gitInitPath = path
    }
    
    public func getRemoteURL(path: String) throws -> String {
        if throwError { throw NSError(domain: "Test", code: 0) }
        return remoteURL
    }
    
    public func getPreviousReleaseVersion(path: String) throws -> String {
        if throwError { throw NSError(domain: "Test", code: 0) }
        return previousVersion
    }
    
    public func remoteRepoInit(tapName: String, path: String, projectDetails: String, visibility: RepoVisibility) throws -> String {
        if throwError { throw NSError(domain: "Test", code: 0) }
        remoteTapPath = path
        remoteTapName = tapName
        return remoteURL
    }
    
    public func createNewRelease(version: String, binaryPath: String, releaseNoteInfo: ReleaseNoteInfo, path: String) throws -> String {
        if throwError { throw NSError(domain: "Test", code: 0) }
        self.releaseVersion = version
        self.releaseNoteInfo = releaseNoteInfo
        return assetURL
    }
}


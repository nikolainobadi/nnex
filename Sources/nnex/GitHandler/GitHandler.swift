//
//  GitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import GitCommandGen

struct GitHandler {
    private let shell: Shell
    
    init(shell: Shell) {
        self.shell = shell
    }
}

extension GitHandler {
    func getRemoteURL(path: String) throws -> String {
        return try shell.run(makeGitCommand(.getRemoteURL, path: path))
    }
    
    func createNewRelease(version: String, binaryPath: String, releaseNotes: String, path: String) throws {
        let command = makeGitHubCommand(.createNewReleaseWithBinary(version: version, binaryPath: binaryPath, releaseNotes: releaseNotes), path: path)
        
        try shell.runAndPrint(command)
    }
    
    func getAssetURL(path: String) throws -> String {
        return try shell.run(makeGitHubCommand(.getLatestReleaseAssetURL, path: path))
    }
    
    func getPreviousReleaseVersion(path: String) throws -> String {
        return try shell.run(makeGitHubCommand(.getPreviousReleaseVersion, path: path))
    }
}

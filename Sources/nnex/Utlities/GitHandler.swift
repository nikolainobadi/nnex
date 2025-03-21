//
//  GitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import GitShellKit

struct GitHandler {
    private let shell: Shell
    private let gitShell: GitShell
    
    init(shell: Shell) {
        self.shell = shell
        self.gitShell = GitShellAdapter(shell: shell)
    }
}


// MARK: - Actions
extension GitHandler {
    func getRemoteURL(path: String) throws -> String {
        return try gitShell.getGitHubURL(at: path)
    }
    
    func getAssetURL(path: String) throws -> String {
        return try shell.run(makeGitHubCommand(.getLatestReleaseAssetURL, path: path))
    }
    
    func getPreviousReleaseVersion(path: String) throws -> String {
        return try shell.run(makeGitHubCommand(.getPreviousReleaseVersion, path: path))
    }
    
    func createNewRepo(name: String, visibility: String, details: String, path: String) throws {
        fatalError() // TODO: - 
    }
    
    func createNewRelease(version: String, binaryPath: String, releaseNotes: String, path: String) throws {
        let command = makeGitHubCommand(.createNewReleaseWithBinary(version: version, binaryPath: binaryPath, releaseNotes: releaseNotes), path: path)
        
        try shell.runAndPrint(command)
    }
}


// MARK: - Dependencies
struct GitShellAdapter {
    private let shell: Shell
    
    init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - GitShell
extension GitShellAdapter: GitShell {
    func runWithOutput(_ command: String) throws -> String {
        return try shell.run(command)
    }
}

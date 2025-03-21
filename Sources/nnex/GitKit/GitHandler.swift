//
//  GitHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import GitShellKit

struct GitHandler {
    private let shell: Shell
    private let picker: Picker
    private let gitShell: GitShell
    
    init(shell: Shell, picker: Picker) {
        self.shell = shell
        self.picker = picker
        self.gitShell = GitShellAdapter(shell: shell)
    }
}


// MARK: - Actions
extension GitHandler {
    func getRemoteURL(path: String) throws -> String {
        return try gitShell.getGitHubURL(at: path)
    }
    
    func getPreviousReleaseVersion(path: String) throws -> String {
        return try shell.run(makeGitHubCommand(.getPreviousReleaseVersion, path: path))
    }
    
    func gitInit(path: String) throws {
        try GitStarter(path: path, shell: gitShell).gitInit()
    }
    
    func remoteRepoInit(tapName: String, path: String, projectDetails: String?, visibility: RepoVisibility) throws -> String {
        let infoProvider = RepoInfoProviderAdapter(picker: picker, tapName: tapName, projectDetails: projectDetails, visibility: visibility)
        
        return try GitHubRepoStarter(path: path, shell: gitShell, infoProvider: infoProvider).repoInit()
    }
    
    func createNewRelease(version: String, binaryPath: String, releaseNotes: String, path: String) throws -> String {
        let command = makeGitHubCommand(.createNewReleaseWithBinary(version: version, binaryPath: binaryPath, releaseNotes: releaseNotes), path: path)
        
        try shell.runAndPrint(command)
        
        return try shell.run(makeGitHubCommand(.getLatestReleaseAssetURL, path: path))
    }
}

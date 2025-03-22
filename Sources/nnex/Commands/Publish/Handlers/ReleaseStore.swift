//
//  ReleaseStore.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import NnexKit

struct ReleaseStore {
    private let picker: Picker
    private let gitHandler: DefaultGitHandler
    
    init(shell: Shell, picker: Picker) {
        self.picker = picker
        self.gitHandler = .init(shell: shell)
    }
}


// MARK: - Upload
extension ReleaseStore {
    func uploadRelease(info: ReleaseInfo) throws -> String {
        let versionNumber = try getVersionNumber(info)
        let assetURL = try gitHandler.createNewRelease(version: versionNumber, binaryPath: info.binaryPath, releaseNotes: info.releaseNotes, path: info.projectPath)
        print("GitHub release \(versionNumber) created and binary uploaded to \(assetURL)")
        
        return assetURL
    }
}


// MARK: - Private Methods
private extension ReleaseStore {
    func incrementVersion(_ part: ReleaseVersionInfo.VersionPart, path: String) throws -> String {
        let previousVersion = try gitHandler.getPreviousReleaseVersion(path: path)
        
        print("found previous version:", previousVersion)
        
        return try VersionHandler.incrementVersion(for: part, path: path, previousVersion: previousVersion)
    }
    
    func getVersionNumber(_ info: ReleaseInfo) throws -> String {
        guard let versionInfo = info.versionInfo else {
            return try getVersionInput(path: info.projectPath)
        }
        
        switch versionInfo {
        case .version(let number):
            guard VersionHandler.isValidVersionNumber(number) else {
                throw NnexError.invalidVersionNumber
            }
            
            return number
        case .increment(let part):
            return try incrementVersion(part, path: info.projectPath)
        }
    }
    
    func getVersionInput(path: String) throws -> String {
        let input = try picker.getRequiredInput(prompt: "Enter the version number for this release.")
        
        if let versionPart = ReleaseVersionInfo.VersionPart(string: input) {
            return try incrementVersion(versionPart, path: path)
        }
        
        guard VersionHandler.isValidVersionNumber(input) else {
            throw NnexError.invalidVersionNumber
        }
        
        return input
    }
}

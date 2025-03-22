//
//  ReleaseStore.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

public struct ReleaseStore {
    private let gitHandler: GitHandler
    
    public init(gitHandler: GitHandler) {
        self.gitHandler = gitHandler
    }
}


// MARK: - Upload
public extension ReleaseStore {
    typealias UploadResult = (assertURL: String, versionNumber: String)
    func uploadRelease(info: ReleaseInfo) throws -> UploadResult {
        let versionNumber = try getVersionNumber(info)
        let assetURL = try gitHandler.createNewRelease(version: versionNumber, binaryPath: info.binaryPath, releaseNotes: info.releaseNotes, path: info.projectPath)
        
        return (assetURL, versionNumber)
    }
}


// MARK: - Private Methods
private extension ReleaseStore {
    func getVersionNumber(_ info: ReleaseInfo) throws -> String {
        switch info.versionInfo {
        case .version(let number):
            guard VersionHandler.isValidVersionNumber(number) else {
                throw NnexError.invalidVersionNumber
            }
            
            return number
        case .increment(let part):
            guard let previousVersion = info.previousVersion else {
                throw NnexError.noPreviousVersionToIncrement
            }
            
            return try VersionHandler.incrementVersion(for: part, path: info.projectPath, previousVersion: previousVersion)
        }
    }
}

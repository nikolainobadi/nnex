//
//  ReleaseStore.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Manages the process of uploading a release to a remote repository.
public struct OldReleaseStore {
    private let gitHandler: any GitHandler

    /// Initializes a new instance of ReleaseStore with a Git handler.
    /// - Parameter gitHandler: The Git handler used for managing releases.
    public init(gitHandler: any GitHandler) {
        self.gitHandler = gitHandler
    }
}


// MARK: - Upload
extension OldReleaseStore {
    /// Represents the result of a successful upload, containing asset URLs and version number.
    public typealias UploadResult = (assetURLs: [String], versionNumber: String)

    /// Uploads a release to the remote repository with archived binaries.
    /// - Parameters:
    ///   - info: The information related to the release.
    ///   - archivedBinaries: The archived binaries to upload to the release.
    /// - Returns: An UploadResult containing all asset URLs and version number.
    /// - Throws: An error if the upload process fails.
    public func uploadRelease(info: OldReleaseInfo, archivedBinaries: [ArchivedBinary]) throws -> UploadResult {
        let versionNumber = try getVersionNumber(info)
        let assetURLs = try gitHandler.createNewRelease(
            version: versionNumber,
            archivedBinaries: archivedBinaries,
            releaseNoteInfo: info.releaseNoteInfo,
            path: info.projectPath
        )
        return (assetURLs, versionNumber)
    }
}


// MARK: - Private Methods
private extension OldReleaseStore {
    /// Determines the version number for the release.
    func getVersionNumber(_ info: OldReleaseInfo) throws -> String {
        switch info.versionInfo {
        case .version(let number):
            guard OldVersionHandler.isValidVersionNumber(number) else {
                throw NnexError.invalidVersionNumber
            }
            return number

        case .increment(let part):
            guard let previousVersion = info.previousVersion else {
                throw NnexError.noPreviousVersionToIncrement
            }
            return try OldVersionHandler.incrementVersion(
                for: part,
                path: info.projectPath,
                previousVersion: previousVersion
            )
        }
    }
}

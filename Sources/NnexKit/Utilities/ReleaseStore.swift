//
//  ReleaseStore.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Manages the process of uploading a release to a remote repository.
public struct ReleaseStore {
    private let gitHandler: GitHandler

    /// Initializes a new instance of ReleaseStore with a Git handler.
    /// - Parameter gitHandler: The Git handler used for managing releases.
    public init(gitHandler: GitHandler) {
        self.gitHandler = gitHandler
    }
}

// MARK: - Upload
extension ReleaseStore {
    /// Represents the result of a successful upload, containing asset URLs and version number.
    public typealias UploadResult = (assetURLs: [String], versionNumber: String)

    /// Uploads a release to the remote repository with optional additional assets.
    /// - Parameters:
    ///   - info: The information related to the release.
    ///   - additionalAssetPaths: Optional additional binary paths to upload to the same release.
    /// - Returns: An UploadResult containing all asset URLs and version number.
    /// - Throws: An error if the upload process fails.
    public func uploadRelease(info: ReleaseInfo, additionalAssetPaths: [String] = []) throws -> UploadResult {
        let versionNumber = try getVersionNumber(info)
        let assetURLs = try gitHandler.createNewRelease(
            version: versionNumber,
            binaryPath: info.binaryPath,
            additionalBinaryPaths: additionalAssetPaths,
            releaseNoteInfo: info.releaseNoteInfo,
            path: info.projectPath
        )
        return (assetURLs, versionNumber)
    }
}

// MARK: - Private Methods
private extension ReleaseStore {
    /// Determines the version number for the release.
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
            return try VersionHandler.incrementVersion(
                for: part,
                path: info.projectPath,
                previousVersion: previousVersion
            )
        }
    }
}

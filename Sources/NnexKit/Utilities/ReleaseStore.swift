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
    /// Represents the result of a successful upload, containing the asset URL and version number.
    public typealias UploadResult = (assertURL: String, versionNumber: String)

    /// Uploads a release to the remote repository.
    /// - Parameter info: The information related to the release.
    /// - Returns: An UploadResult containing the asset URL and version number.
    /// - Throws: An error if the upload process fails.
    public func uploadRelease(info: ReleaseInfo) throws -> UploadResult {
        let versionNumber = try getVersionNumber(info)
        let assetURL = try gitHandler.createNewRelease(
            version: versionNumber,
            binaryPath: info.binaryPath,
            releaseNoteInfo: info.releaseNoteInfo,
            path: info.projectPath
        )

        return (assetURL, versionNumber)
    }
}


// MARK: - Private Methods
private extension ReleaseStore {
    /// Determines the version number for the release.
    /// - Parameter info: The release information containing version details.
    /// - Returns: The resolved version number as a string.
    /// - Throws: An error if the version number could not be determined.
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

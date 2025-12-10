//
//  ReleaseNotesFileUtility.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import NnexKit
import Foundation
import GitCommandGen

/// Utility for creating and validating release notes files.
struct OldReleaseNotesFileUtility {
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let dateProvider: any DateProvider

    /// Initializes a new ReleaseNotesFileUtility instance.
    /// - Parameters:
    ///   - picker: The picker for user interactions.
    ///   - fileSystem: The file system provider.
    ///   - dateProvider: The date provider.
    init(picker: any NnexPicker, fileSystem: any FileSystem, dateProvider: any DateProvider) {
        self.picker = picker
        self.fileSystem = fileSystem
        self.dateProvider = dateProvider
    }
}


// MARK: - Public Methods
extension OldReleaseNotesFileUtility {
    /// Creates and opens a new release notes file on the desktop.
    /// - Parameter projectName: The name of the project for the filename.
    /// - Returns: The path to the created file.
    /// - Throws: An error if file creation fails.
    func createAndOpenNewNoteFile(projectName: String) throws -> String {
        let desktop = try fileSystem.desktopDirectory()
        let fileName = "\(projectName)-releaseNotes-\(dateProvider.currentDate.shortFormat).md"
        
        return try desktop.createFile(named: fileName, contents: "")
    }

    /// Creates a new release notes file with a specific version number.
    /// - Parameters:
    ///   - projectName: The name of the project for the filename.
    ///   - version: The version number for the filename.
    /// - Returns: The path to the created file.
    /// - Throws: An error if file creation fails.
    func createVersionedNoteFile(projectName: String, version: String) throws -> String {
        let desktop = try fileSystem.desktopDirectory()
        let fileName = "\(projectName)-releaseNotes-v\(version).md"
        
        return try desktop.createFile(named: fileName, contents: "")
    }

    /// Validates and confirms a release notes file with the user.
    /// - Parameter filePath: The path to the file to validate.
    /// - Returns: A ReleaseNoteInfo instance containing the file path.
    /// - Throws: An error if validation fails or the file is empty after retry.
    func validateAndConfirmNoteFile(_ filePath: String) throws -> ReleaseNoteInfo {
        try picker.requiredPermission(prompt: "Did you add your release notes to \(filePath)?")

        let notesContent = try fileSystem.readFile(at: filePath)

        if notesContent.isEmpty {
            try picker.requiredPermission(prompt: "The file looks empty. Make sure to save your changes then type 'y' to proceed. Type 'n' to cancel")

            let notesContent = try fileSystem.readFile(at: filePath)

            if notesContent.isEmpty {
                throw ReleaseNotesError.emptyFileAfterRetry(filePath: filePath)
            }
        }

        return .init(content: filePath, isFromFile: true)
    }
}


// MARK: - Dependencies
protocol DateProvider {
    var currentDate: Date { get }
}


// MARK: - Extension Dependencies
private extension Date {
    /// Formats the date as "M-d-yy" (e.g., "3-24-25").
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: self)
    }
}

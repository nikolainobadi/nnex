//
//  ReleaseNotesFileUtility.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import Foundation
import GitCommandGen

/// Utility for creating and validating release notes files.
struct ReleaseNotesFileUtility {
    private let picker: NnexPicker
    private let fileSystem: FileSystemProvider
    private let dateProvider: DateProvider
    
    /// Initializes a new ReleaseNotesFileUtility instance.
    /// - Parameters:
    ///   - picker: The picker for user interactions.
    ///   - fileSystem: The file system provider.
    ///   - dateProvider: The date provider.
    init(picker: NnexPicker, fileSystem: FileSystemProvider = DefaultFileSystemProvider(), dateProvider: DateProvider = DefaultDateProvider()) {
        self.picker = picker
        self.fileSystem = fileSystem
        self.dateProvider = dateProvider
    }
}


// MARK: - Public Methods
extension ReleaseNotesFileUtility {
    /// Creates and opens a new release notes file on the desktop.
    /// - Parameter projectName: The name of the project for the filename.
    /// - Returns: A FileProtocol instance representing the created file.
    /// - Throws: An error if file creation fails.
    func createAndOpenNewNoteFile(projectName: String) throws -> FileProtocol {
        let desktopPath = try Folder.home.subfolder(named: "Desktop").path
        let fileName = "\(projectName)-releaseNotes-\(dateProvider.currentDate.shortFormat).md"
        return try fileSystem.createFile(in: desktopPath, named: fileName)
    }
    
    /// Creates a new release notes file with a specific version number.
    /// - Parameters:
    ///   - projectName: The name of the project for the filename.
    ///   - version: The version number for the filename.
    /// - Returns: A FileProtocol instance representing the created file.
    /// - Throws: An error if file creation fails.
    func createVersionedNoteFile(projectName: String, version: String) throws -> FileProtocol {
        let desktopPath = try Folder.home.subfolder(named: "Desktop").path
        let fileName = "\(projectName)-releaseNotes-v\(version).md"
        return try fileSystem.createFile(in: desktopPath, named: fileName)
    }
    
    /// Validates and confirms a release notes file with the user.
    /// - Parameter file: The file to validate.
    /// - Returns: A ReleaseNoteInfo instance containing the file path.
    /// - Throws: An error if validation fails or the file is empty after retry.
    func validateAndConfirmNoteFile(_ file: FileProtocol) throws -> ReleaseNoteInfo {
        try picker.requiredPermission(prompt: "Did you add your release notes to \(file.path)?")
        
        let notesContent = try file.readAsString()
        
        if notesContent.isEmpty {
            try picker.requiredPermission(prompt: "The file looks empty. Make sure to save your changes then type 'y' to proceed. Type 'n' to cancel")
            
            let notesContent = try file.readAsString()
            
            if notesContent.isEmpty {
                throw ReleaseNotesError.emptyFileAfterRetry(filePath: file.path)
            }
        }
        
        return .init(content: file.path, isFromFile: true)
    }
}






// MARK: - Dependencies
protocol DateProvider {
    var currentDate: Date { get }
}

protocol FileProtocol {
    var path: String { get }
    func readAsString() throws -> String
}

protocol FileSystemProvider {
    func createFile(in folderPath: String, named: String) throws -> FileProtocol
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
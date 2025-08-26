//
//  ReleaseNotesHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import Foundation
import GitCommandGen

struct ReleaseNotesHandler {
    private let picker: NnexPicker
    private let projectName: String
    private let fileSystem: FileSystemProvider
    private let dateProvider: DateProvider
    
    init(picker: NnexPicker, projectName: String, fileSystem: FileSystemProvider = DefaultFileSystemProvider(), dateProvider: DateProvider = DefaultDateProvider()) {
        self.picker = picker
        self.projectName = projectName
        self.fileSystem = fileSystem
        self.dateProvider = dateProvider
    }
}


// MARK: - Action
extension ReleaseNotesHandler {
    func getReleaseNoteInfo() throws -> ReleaseNoteInfo {
        switch try picker.requiredSingleSelection(title: "How would you like to add your release notes for \(projectName)?", items: NoteContentType.allCases) {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
            
            return .init(content: notes, isFromFile: false)
        case .fromPath:
            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for the \(projectName) release notes.")
            
            return .init(content: filePath, isFromFile: true)
        case .createFile:
            let releaseNotesFile = try createAndOpenNewNoteFile()
            
            return try decodeNoteFile(releaseNotesFile)
        }
    }
}


// MARK: - Private Helpers
private extension ReleaseNotesHandler {
    func createAndOpenNewNoteFile() throws -> FileProtocol {
        let desktopPath = try Folder.home.subfolder(named: "Desktop").path
        let fileName = "\(projectName)-releaseNotes-\(dateProvider.currentDate.shortFormat).md"
        return try fileSystem.createFile(in: desktopPath, named: fileName)
    }
    
    func decodeNoteFile(_ file: FileProtocol) throws -> ReleaseNoteInfo {
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

extension ReleaseNotesHandler {
    enum NoteContentType: CaseIterable {
        case direct, fromPath, createFile
    }
}


// MARK: - Extension Dependencies
private extension Date {
    /// Formats the date as "M-d-yy- (e.g., "3-24-25").
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: self)
    }
}

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
    private let picker: Picker
    private let projectName: String
    
    init(picker: Picker, projectName: String) {
        self.picker = picker
        self.projectName = projectName
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
    func createAndOpenNewNoteFile() throws -> File {
        // TODO: - this isn't fit for unit testing yet, so a refactor may be required
        let desktop = try Folder.home.subfolder(named: "Desktop")
        let releaseNotesFile = try desktop.createFile(named: "\(projectName)-releaseNotes-\(Date().shortFormat).md")
        
        releaseNotesFile.open()
        return releaseNotesFile
    }
    
    func decodeNoteFile(_ file: File) throws -> ReleaseNoteInfo {
        try picker.requiredPermission(prompt: "Did you add your release notes to \(file.path)?")
        
        let notesContent = try file.readAsString()
        
        if notesContent.isEmpty {
            try picker.requiredPermission(prompt: "The file looks empty. Make sure to save your changes then type 'y' to proceed. Type 'n' to cancel")
            
            let notesContent = try file.readAsString()
            
            if notesContent.isEmpty {
                fatalError("You still didn't add any notes to \(file.path)...I'm done with you")
            }
        }
        
        return .init(content: file.path, isFromFile: true)
    }
}


// MARK: - Dependencies
enum NoteContentType: CaseIterable {
    case direct, fromPath, createFile
}


// MARK: - Extension Dependencies
fileprivate extension Date {
    /// Formats the date as "M-d-yy- (e.g., "3-24-25").
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: self)
    }
}

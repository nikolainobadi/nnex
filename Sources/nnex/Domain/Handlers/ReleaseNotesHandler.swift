//
//  ReleaseNotesHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import NnexKit
import Foundation
import GitCommandGen

struct ReleaseNotesHandler {
    private let picker: any NnexPicker
    private let projectName: String
    private let fileUtility: ReleaseNotesFileUtility
    
    init(picker: any NnexPicker, projectName: String, fileUtility: ReleaseNotesFileUtility) {
        self.picker = picker
        self.projectName = projectName
        self.fileUtility = fileUtility
    }
}


// MARK: - Action
extension ReleaseNotesHandler {
    func getReleaseNoteInfo() throws -> ReleaseNoteInfo {
        switch try picker.requiredSingleSelection("How would you like to add your release notes for \(projectName)?", items: NoteContentType.allCases) {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
            
            return .init(content: notes, isFromFile: false)
        case .selectFile:
            let homeDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
            guard let selection = picker.browseDirectories(prompt: "Select the file containing your release notes.", startURL: homeDirectoryURL, showPromptText: true, showSelectedItemText: true, selectionType: .onlyFiles) else {
                throw NnexError.selectionRequired
            }
            
            return .init(content: selection.url.path(), isFromFile: true)
        case .fromPath:
            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for the \(projectName) release notes.")
            
            return .init(content: filePath, isFromFile: true)
        case .createFile:
            let releaseNotesFile = try fileUtility.createAndOpenNewNoteFile(projectName: projectName)
            
            return try fileUtility.validateAndConfirmNoteFile(releaseNotesFile)
        }
    }
}


// MARK: - Dependencies
extension ReleaseNotesHandler {
    enum NoteContentType: CaseIterable {
        case direct, selectFile, fromPath, createFile
    }
}

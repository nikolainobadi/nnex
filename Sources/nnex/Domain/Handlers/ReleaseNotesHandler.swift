//
//  ReleaseNotesHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import Foundation
import GitCommandGen
import NnShellKit

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
        switch try picker.requiredSingleSelection(title: "How would you like to add your release notes for \(projectName)?", items: NoteContentType.allCases) {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
            
            return .init(content: notes, isFromFile: false)
        case .selectFile:
            fatalError() // TODO: - 
        case .fromPath:
            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for the \(projectName) release notes.")
            
            return .init(content: filePath, isFromFile: true)
        case .createFile:
            let releaseNotesFile = try fileUtility.createAndOpenNewNoteFile(projectName: projectName)
            
            return try fileUtility.validateAndConfirmNoteFile(releaseNotesFile)
        }
    }
}


extension ReleaseNotesHandler {
    enum NoteContentType: CaseIterable {
        case direct, selectFile, fromPath, createFile
    }
}


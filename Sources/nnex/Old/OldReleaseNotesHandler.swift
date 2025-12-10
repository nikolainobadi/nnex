//
//  ReleaseNotesHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Files
import Foundation
import GitCommandGen

struct OldReleaseNotesHandler {
    private let picker: any NnexPicker
    private let projectName: String
    private let fileUtility: OldReleaseNotesFileUtility
    
    init(picker: any NnexPicker, projectName: String, fileUtility: OldReleaseNotesFileUtility) {
        self.picker = picker
        self.projectName = projectName
        self.fileUtility = fileUtility
    }
}


// MARK: - Action
extension OldReleaseNotesHandler {
    func getReleaseNoteInfo() throws -> ReleaseNoteInfo {
        switch try picker.requiredSingleSelection("How would you like to add your release notes for \(projectName)?", items: OldNoteContentType.allCases) {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
            
            return .init(content: notes, isFromFile: false)
        case .selectFile:
            fatalError() // TODO: - need to abstract Files in order to enable this
//            let selection = try picker.requiredBrowseSelection(prompt: "Select the file containing your release notes", allowSelectingFolders: false)
//            
//            return .init(content: selection.url.path(), isFromFile: true)
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
extension OldReleaseNotesHandler {
    enum OldNoteContentType: CaseIterable {
        case direct, selectFile, fromPath, createFile
    }
}

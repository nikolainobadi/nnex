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
    private let picker: NnexPicker
    private let projectName: String
    private let fileUtility: ReleaseNotesFileUtility
    private let aiReleaseEnabled: Bool
    
    init(picker: NnexPicker, projectName: String, aiReleaseEnabled: Bool = false, fileUtility: ReleaseNotesFileUtility? = nil) {
        self.picker = picker
        self.projectName = projectName
        self.aiReleaseEnabled = aiReleaseEnabled
        self.fileUtility = fileUtility ?? ReleaseNotesFileUtility(picker: picker)
    }
}


// MARK: - Action
extension ReleaseNotesHandler {
    func getReleaseNoteInfo(releaseNumber: String? = nil, projectPath: String? = nil, shell: (any Shell)? = nil) throws -> ReleaseNoteInfo {
        let availableOptions = aiReleaseEnabled ? NoteContentType.allCases : NoteContentType.allCases.filter { $0 != .aiGenerated }
        
        switch try picker.requiredSingleSelection(title: "How would you like to add your release notes for \(projectName)?", items: availableOptions) {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
            
            return .init(content: notes, isFromFile: false)
        case .fromPath:
            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for the \(projectName) release notes.")
            
            return .init(content: filePath, isFromFile: true)
        case .createFile:
            let releaseNotesFile = try fileUtility.createAndOpenNewNoteFile(projectName: projectName)
            
            return try fileUtility.validateAndConfirmNoteFile(releaseNotesFile)
        case .aiGenerated:
            guard let releaseNumber, let projectPath, let shell else {
                throw ReleaseNotesError.missingAIRequirements
            }
            
            let aiHandler = AIReleaseNotesHandler(
                projectName: projectName,
                shell: shell,
                picker: picker,
                fileUtility: fileUtility
            )
            
            return try aiHandler.generateReleaseNotes(releaseNumber: releaseNumber, projectPath: projectPath)
        }
    }
}


extension ReleaseNotesHandler {
    enum NoteContentType: CaseIterable {
        case direct, fromPath, createFile, aiGenerated
    }
}


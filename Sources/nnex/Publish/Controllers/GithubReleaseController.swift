//
//  GithubReleaseController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit
import Foundation
import GitShellKit

struct GithubReleaseController {
    private let picker: any NnexPicker
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let dateProvider: any DateProvider
    private let folderBrowser: any DirectoryBrowser
    
    init(picker: any NnexPicker, gitHandler: any GitHandler, fileSystem: any FileSystem, dateProvider: any DateProvider, folderBrowser: any DirectoryBrowser) {
        self.picker = picker
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
        self.dateProvider = dateProvider
        self.folderBrowser = folderBrowser
    }
}


// MARK: - UploadRelease
extension GithubReleaseController {
    func uploadRelease(version: String, assets: [ArchivedBinary], notes: String?, notesFilePath: String?, projectFolder: any Directory) throws -> [String] {
        let noteSource = try selectReleaseNoteSource(notes: notes, notesFilePath: notesFilePath, projectName: projectFolder.name)
        
        return try gitHandler.createNewRelease(version: version, archivedBinaries: assets, releaseNoteInfo: noteSource.gitShellInfo, path: projectFolder.path)
    }
}


// MARK: - Private Methods
private extension GithubReleaseController {
    func selectReleaseNoteSource(notes: String?, notesFilePath: String?, projectName: String) throws -> ReleaseNoteSource {
        if let notes {
            return .exact(notes)
        }
        
        if let notesFilePath {
            return .filePath(notesFilePath)
        }
        
        switch try picker.requiredSingleSelection("How would you like to add your release notes for \(projectName)?", items: NoteContentType.allCases) {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
            
            return .exact(notes)
        case .selectFile:
            let filePath = try folderBrowser.browseForFile(prompt: "Select the file containing your release notes.")
            
            return .filePath(filePath)
        case .fromPath:
            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for the \(projectName) release notes.")
            
            return .filePath(filePath)
        case .createFile:
            let filePath = try createAndOpenNewNoteFile(projectName: projectName)
            let confirmedPath = try validateAndConfirmNoteFilePath(filePath)
            
            return .filePath(confirmedPath)
        }
    }
    
    func createAndOpenNewNoteFile(projectName: String) throws -> String {
        let desktop = try fileSystem.desktopDirectory()
        let fileName = "\(projectName)-releaseNotes-\(dateProvider.currentDate.shortFormat).md"
        
        return try desktop.createFile(named: fileName, contents: "")
    }
    
    func validateAndConfirmNoteFilePath(_ filePath: String) throws -> String {
        try picker.requiredPermission(prompt: "Did you add your release notes to \(filePath)?")

        let notesContent = try fileSystem.readFile(at: filePath)

        if notesContent.isEmpty {
            try picker.requiredPermission(prompt: "The file looks empty. Make sure to save your changes then type 'y' to proceed. Type 'n' to cancel")

            let notesContent = try fileSystem.readFile(at: filePath)

            if notesContent.isEmpty {
                throw ReleaseNotesError.emptyFileAfterRetry(filePath: filePath)
            }
        }

        return filePath
    }
}


// MARK: - Dependencies
protocol DateProvider {
    var currentDate: Date { get }
}


// MARK: - Extension Dependencies
private extension Date {
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: self)
    }
}

private extension ReleaseNoteSource {
    var gitShellInfo: ReleaseNoteInfo {
        switch self {
        case .exact(let notes):
            return .init(content: notes, isFromFile: false)
        case .filePath(let filePath):
            return .init(content: filePath, isFromFile: true)
        }
    }
}

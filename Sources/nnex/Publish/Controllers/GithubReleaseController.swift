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
        let assetURLs = try gitHandler.createNewRelease(version: version, archivedBinaries: assets, releaseNoteInfo: noteSource.gitShellInfo, path: projectFolder.path)
        
        moveNotesToTrashIfNecessary(noteSource: noteSource)
        
        return assetURLs
    }
}


// MARK: - Private Methods
private extension GithubReleaseController {
    func moveNotesToTrashIfNecessary(noteSource: ReleaseNoteSource) {
        switch noteSource {
        case .filePath(let filePath):
            if picker.getPermission(prompt: "Release notes uploaded. Would you like to move them to the trash?") {
                try? fileSystem.moveToTrash(at: filePath)
            }
        default:
            break
        }
    }
    
    func selectReleaseNoteSource(notes: String?, notesFilePath: String?, projectName: String) throws -> ReleaseNoteSource {
        let noteSource: ReleaseNoteSource

        if let notes {
            noteSource = .exact(notes)
        } else if let notesFilePath {
            noteSource = .filePath(notesFilePath)
        } else {
            noteSource = try selectReleaseNoteSourceInteractively(projectName: projectName)
        }

        return noteSource
    }

    func selectReleaseNoteSourceInteractively(projectName: String) throws -> ReleaseNoteSource {
        switch try picker.requiredSingleSelection("How would you like to add your release notes for \(projectName)?", items: NoteContentType.allCases, showSelectedItemText: false) {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")

            return .exact(notes)
        case .selectFile:
            let filePath = try folderBrowser.browseForFile(prompt: "Select the file containing your release notes.")
            let confirmationPrompt = """
            
            Release notes file path: \(filePath)

            Proceed with this file?
            """
            
            try picker.requiredPermission(prompt: confirmationPrompt)

            return .filePath(filePath)
        case .fromPath:
            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for the \(projectName) release notes.")

            return .filePath(filePath)
        case .createFile:
            let desktop = try fileSystem.desktopDirectory()
            let fileName = "\(projectName)-releaseNotes-\(dateProvider.currentDate.shortFormat).md"
            let filePath = try desktop.createFile(named: fileName, contents: "")

            try picker.requiredPermission(prompt: "Did you add your release notes to \(filePath)?")

            let notesContent = try desktop.readFile(named: fileName)

            if notesContent.isEmpty {
                try picker.requiredPermission(prompt: "The file looks empty. Make sure to save your changes then type 'y' to proceed. Type 'n' to cancel")

                let recheckContent = try desktop.readFile(named: fileName)

                if recheckContent.isEmpty {
                    throw ReleaseNotesError.emptyFileAfterRetry(filePath: filePath)
                }
            }

            return .filePath(fileName)
        }
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

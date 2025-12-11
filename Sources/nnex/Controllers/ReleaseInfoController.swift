//
//  ReleaseInfoController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

import NnexKit
import Foundation

struct ReleaseInfoController {
    private let picker: any NnexPicker
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let dateProvider: any DateProvider
    private let folderBrowser: any DirectoryBrowser
}


// MARK: - ReleaseInfoService
extension ReleaseInfoController {
    func makeReleaseInfo(projectFolder: any Directory, versionSpecifier: ReleaseVersionSpecifier?, notes: ReleaseNotes?) throws -> (ReleaseVersionSpecifier, ReleaseNotes) {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: projectFolder.path)
        let version = try selectReleaseNumber(previous: previousVersion, versionSpecifier: versionSpecifier)
        let notes = try selectReleaseNoteSource(notes: notes, projectName: projectFolder.name)
        
        return (version, notes)
    }
}


// MARK: - Private Methods
private extension ReleaseInfoController {
    func selectReleaseNumber(previous: String?, versionSpecifier: ReleaseVersionSpecifier?) throws -> ReleaseVersionSpecifier {
        if let versionSpecifier {
            return versionSpecifier
        }

        let promptPrefix: String

        if let previous {
            promptPrefix = "Previous Version: \(previous)."
        } else {
            promptPrefix = "No previous version detected."
        }

        let prompt = "\(promptPrefix)\nSelect which component to increment for this release."
        let selection = try picker.requiredSingleSelection(prompt, items: ReleaseComponent.allCases)

        return .increment(selection)
    }

    func selectReleaseNoteSource(notes: ReleaseNotes?, projectName: String) throws -> ReleaseNotes {
        if let notes {
            return notes
        }

        let selection = try picker.requiredSingleSelection("How would you like to provide notes for this release?", items: NoteContentType.allCases)

        switch selection {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")

            return .text(notes)
        case .selectFile:
            let filePath = try folderBrowser.browseForFile(prompt: "Select your release notes file.")

            return .filePath(filePath)
        case .fromPath:
            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for your release notes.")

            return .filePath(filePath)
        case .createFile:
            let filePath = try createAndOpenNewNoteFile(projectName: projectName)

            return try validateAndConfirmNoteFile(filePath)
        }
    }

    func createAndOpenNewNoteFile(projectName: String) throws -> String {
        let desktop = try fileSystem.desktopDirectory()
        let fileName = "\(projectName)-releaseNotes-\(dateProvider.currentDate.shortFormat).md"

        return try desktop.createFile(named: fileName, contents: "")
    }

    func validateAndConfirmNoteFile(_ filePath: String) throws -> ReleaseNotes {
        try picker.requiredPermission(prompt: "Did you add your release notes to \(filePath)?")

        let notesContent = try fileSystem.readFile(at: filePath)

        if notesContent.isEmpty {
            try picker.requiredPermission(prompt: "The file looks empty. Make sure to save your changes then type 'y' to proceed. Type 'n' to cancel")

            let notesContent = try fileSystem.readFile(at: filePath)

            if notesContent.isEmpty {
                throw ReleaseNotesError.emptyFileAfterRetry(filePath: filePath)
            }
        }

        return .filePath(filePath)
    }
}


// MARK: - Dependencies
enum NoteContentType: CaseIterable {
    case direct
    case selectFile
    case fromPath
    case createFile
}


// MARK: - Extension Dependencies
private extension Date {
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: self)
    }
}

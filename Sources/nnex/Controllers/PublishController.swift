//
//  PublishController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import Foundation
import NnexKit

struct PublishController {
    private let picker: any NnexPicker
    private let folderBrowser: any DirectoryBrowser
    private let fileSystem: any FileSystem
    private let dateProvider: any DateProvider
    private let preparationService: any PublishPreparationService
    private let service: any PublishService
}


// MARK: - Actions
extension PublishController {
    func publish(projectPath: String?, releaseNumber: ReleaseVersionSpecifier?, notes: ReleaseNotes?, commitMessage: String?) throws {
        let projectFolder = try selectProjectFolder(at: projectPath)
        let previousVersion = try preparationService.previousReleaseVersion(projectPath: projectFolder.path)
        let releaseSpecifier = try selectReleaseNumber(previous: previousVersion, releaseNumber: releaseNumber)
        let releaseNotes = try selectReleaseNoteSource(noteSource: notes, projectName: projectFolder.name)
        let tap = try selectTap(projectName: projectFolder.name)
        let formula = try resolveFormula(projectName: projectFolder.name, in: tap)
        let buildConfig = try preparationService.makeBuildConfig(projectName: projectFolder.name, projectPath: projectFolder.path, testCommand: nil)
        let request = makePublishRequest(projectFolder: projectFolder, tap: tap, formula: formula, releaseSpecifier: releaseSpecifier, notes: releaseNotes, commitMessage: commitMessage, buildConfig: buildConfig, previousVersion: previousVersion)

        try service.publish(request: request)
    }
}


// MARK: - Project Selection
private extension PublishController {
    func selectProjectFolder(at path: String?) throws -> any Directory {
        guard let path else {
            return fileSystem.currentDirectory
        }

        return try fileSystem.directory(at: path)
    }
}


// MARK: - Release Version and Notes
private extension PublishController {
    func selectReleaseNumber(previous: String?, releaseNumber: ReleaseVersionSpecifier?) throws -> ReleaseVersionSpecifier {
        if let releaseNumber {
            return releaseNumber
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

    func selectReleaseNoteSource(noteSource: ReleaseNotes?, projectName: String) throws -> ReleaseNotes {
        if let noteSource {
            return noteSource
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


// MARK: - Tap and Formula
private extension PublishController {
    func selectTap(projectName: String) throws -> HomebrewTap {
        let taps = try preparationService.availableTaps()

        if let tap = taps.first(where: { tap in
            return tap.formulas.contains(where: { $0.name.lowercased() == projectName.lowercased() })
        }) {
            return tap
        }

        return try picker.requiredSingleSelection("Select the Homebrew tap for \(projectName)", items: taps)
    }

    func resolveFormula(projectName: String, in tap: HomebrewTap) throws -> HomebrewFormula {
        if let formula = try preparationService.resolveFormula(named: projectName, in: tap) {
            return formula
        }

        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectName.yellow) in \(tap.name). Would you like to create a new one?")

        return try preparationService.createFormula(named: projectName, in: tap)
    }
}


// MARK: - Publish Request
private extension PublishController {
    func makePublishRequest(projectFolder: any Directory, tap: HomebrewTap, formula: HomebrewFormula, releaseSpecifier: ReleaseVersionSpecifier, notes: ReleaseNotes, commitMessage: String?, buildConfig: BuildConfig, previousVersion: String?) -> PublishRequest {
        let releasePlan = makeReleasePlan(previousVersion: previousVersion, releaseSpecifier: releaseSpecifier)
        
        return PublishRequest(projectName: projectFolder.name, projectPath: projectFolder.path, tap: tap, formula: formula, releasePlan: releasePlan, notes: notes, buildConfig: buildConfig, commitMessage: commitMessage)
    }

    func makeReleasePlan(previousVersion: String?, releaseSpecifier: ReleaseVersionSpecifier) -> ReleasePlan {
        return .init(previousVersion: previousVersion, next: releaseSpecifier)
    }
}


// MARK: - Dependencies
protocol PublishService {
    func publish(request: PublishRequest) throws
}

protocol PublishPreparationService {
    func previousReleaseVersion(projectPath: String) throws -> String?
    func availableTaps() throws -> [HomebrewTap]
    func resolveFormula(named name: String, in tap: HomebrewTap) throws -> HomebrewFormula?
    func createFormula(named name: String, in tap: HomebrewTap) throws -> HomebrewFormula
    func makeBuildConfig(projectName: String, projectPath: String, testCommand: TestCommand?) throws -> BuildConfig
}

extension PublishController {
    enum NoteContentType: CaseIterable {
        case direct
        case selectFile
        case fromPath
        case createFile
    }
}


// MARK: - Extension Dependencies
private extension Date {
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: self)
    }
}

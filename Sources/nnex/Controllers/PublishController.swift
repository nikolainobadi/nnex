//
//  PublishController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

import NnexKit

struct PublishController {
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let gitHandler: any GitHandler
}


// MARK: - Actions
extension PublishController {
    func publish(projectPath: String?, releaseNumber: ReleaseNumber?, noteSource: ReleaseNoteSource?) throws {
        let projectFolder = try selectProjectFolder(at: projectPath)
        
        try verifyGitRequirements(at: projectFolder.path)
        
        let releaseInfo = try selectReleaseInfo(projectPath: projectFolder.path, releaseNumber: releaseNumber, noteSource: noteSource)
        let formulaInfo = try loadFormulaInfo()
        let archivedBinaries = try buildAndArchiveBinaries()
        let githubInfo = try uploadRelease(folder: projectFolder, binaries: archivedBinaries, releaseInfo: releaseInfo)
        let formulaContent = try makeFormulaContent(formula: formulaInfo.formula, binaries: archivedBinaries, githubInfo: githubInfo)

        try publishFormula(formulaContent)
    }
}


// MARK: - Private Methods
private extension PublishController {
    func verifyGitRequirements(at path: String) throws {
        // TODO: -
    }
    
    func selectProjectFolder(at path: String?) throws -> any Directory {
        guard let path else {
            return fileSystem.currentDirectory
        }
        
        return try fileSystem.directory(at: path)
    }
    
    func selectReleaseInfo(projectPath: String, releaseNumber: ReleaseNumber?, noteSource: ReleaseNoteSource?) throws -> ReleaseInfo {
        let previous = try? gitHandler.getPreviousReleaseVersion(path: projectPath)
        let nextReleaseNumber = try selectReleaseNumber(previous: previous, releaseNumber: releaseNumber)
        let releaseNoteSource = try selectReleaseNoteSource(noteSource: noteSource)
        
        return .init(previous: previous, nextRelease: nextReleaseNumber, noteSource: releaseNoteSource)
    }
    
    func selectReleaseNumber(previous: String?, releaseNumber: ReleaseNumber?) throws -> ReleaseNumber {
        if let releaseNumber {
            return releaseNumber
        }
    
        let promptPrefix: String
        
        if let previous {
            promptPrefix = "Previous Version: \(previous)."
        } else {
            promptPrefix = "No previous version detected."
        }
        
        // TODO: - may need to add option for custom input
        let prompt = "\(promptPrefix)\nSelect which componenet to increment for this release."
        let selection = try picker.requiredSingleSelection(prompt, items: ReleaseNumber.Component.allCases)
        
        return .increment(selection)
    }
    
    func selectReleaseNoteSource(noteSource: ReleaseNoteSource?) throws -> ReleaseNoteSource {
        if let noteSource {
            return noteSource
        }
        
        let selection = try picker.requiredSingleSelection("How would you like to provide notes for this release?", items: NoteContentType.allCases)
        
        switch selection {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
            
            return .direct(notes)
        case .selectFile:
            fatalError() // TODO: -
        case .fromPath:
            let filePath = try picker.getRequiredInput(prompt: "Enter the path to the file for your release notes.")
            
            return .filePath(filePath)
        case .createFile:
            fatalError() // TODO: -
        }
    }
    
    func loadFormulaInfo() throws -> FormulaInfo {
        fatalError() // TODO: -
    }
    
    func buildAndArchiveBinaries() throws -> [BinaryOutput] {
        return [] // TODO: -
    }
    
    func uploadRelease(folder: any Directory, binaries: [BinaryOutput], releaseInfo: ReleaseInfo) throws -> GithubAssetInfo {
        fatalError() // TODO: -
    }
    
    func makeFormulaContent(formula: HomebrewFormula, binaries: [BinaryOutput], githubInfo: GithubAssetInfo) throws -> String {
        fatalError() // TODO: -
    }
    
    func publishFormula(_ content: String) throws {
        fatalError() // TODO: -
    }
}


// MARK: - Dependencies
extension PublishController {
    enum ReleaseNumber {
        case exact(String)
        case increment(Component)
        
        enum Component: String, CaseIterable {
            case major, minor, patch
        }
    }
    
    struct ReleaseInfo {
        let previous: String?
        let nextRelease: ReleaseNumber
        let noteSource: ReleaseNoteSource
    }
    
    struct FormulaInfo {
        let tap: HomebrewTap
        let formula: HomebrewFormula
    }
    
    struct GithubAssetInfo {
        let version: String
        let assetURLs: [String]
    }
    
    enum ReleaseNoteSource {
        case direct(String)
        case filePath(String)
    }
    
    enum NoteContentType: CaseIterable {
        case direct, selectFile, fromPath, createFile
    }
}

import SwiftPickerKit

extension PublishController.ReleaseNumber.Component: DisplayablePickerItem {
    var displayName: String {
        return rawValue
    }
}

extension PublishController.NoteContentType: DisplayablePickerItem {
    var displayName: String {
        switch self {
        case .direct:
            return "Type notes directly"
        case .selectFile:
            return "Browse and select file"
        case .fromPath:
            return "Enter path to release notes file"
        case .createFile:
            return "Create a new file"
        }
    }
}

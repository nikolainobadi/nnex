//
//  PublishController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

import NnexKit
import Foundation

struct PublishController {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let gitHandler: any GitHandler
    private let service: any PublishService
    private let dateProvider: any DateProvider
    private let trashHandler: any TrashHandler
    private let folderBrowser: any DirectoryBrowser
}


// MARK: - Actions
extension PublishController {
    func publish(projectPath: String?, releaseNumber: ReleaseNumber?, noteSource: ReleaseNoteSource?, commitMessage: String?) throws {
        let projectFolder = try selectProjectFolder(at: projectPath)
        
        try verifyGitRequirements(at: projectFolder.path)
        
        let releaseInfo = try selectReleaseInfo(projectFolder: projectFolder, releaseNumber: releaseNumber, noteSource: noteSource)
        let formulaInfo = try loadFormulaInfo(projectName: projectFolder.name)
        let archivedBinaries = try buildAndArchiveBinaries(formula: formulaInfo.formula)
        let githubInfo = try uploadRelease(folder: projectFolder, archivedBinaries: archivedBinaries, releaseInfo: releaseInfo)
        let formulaContent = try makeFormulaContent(formula: formulaInfo.formula, archivedBinaries: archivedBinaries, githubInfo: githubInfo)

        try publishFormula(formulaContent, formulaInfo: formulaInfo, commitMessage: commitMessage)
    }
}


// MARK: - Private Methods
private extension PublishController {
    func selectProjectFolder(at path: String?) throws -> any Directory {
        guard let path else {
            return fileSystem.currentDirectory
        }
        
        return try fileSystem.directory(at: path)
    }
}


// MARK: - GitRequirements
private extension PublishController {
    func verifyGitRequirements(at path: String) throws {
        try gitHandler.checkForGitHubCLI()
        try ensureNoUncommittedChanges(at: path)
        try checkForMainBranch(at: path)
    }
    
    func ensureNoUncommittedChanges(at path: String) throws {
        let result = try shell.bash("cd \"\(path)\" && git status --porcelain")
        
        if !result.isEmpty {
            print("""
            There are uncommitted changes in the repository at \(path.yellow):
            
            \(result)
            """)
            
            guard picker.getPermission(prompt: "Do you want to proceed even with the uncommitted changes?") else {
                throw PublishExecutionError.uncommittedChanges
            }
        }
    }
    
    func checkForMainBranch(at path: String) throws {
        // TODO: -
    }
}


// MARK: - ReleaseInfoSelection
private extension PublishController {
    func selectReleaseInfo(projectFolder: any Directory, releaseNumber: ReleaseNumber?, noteSource: ReleaseNoteSource?) throws -> ReleaseInfo {
        let previous = try? gitHandler.getPreviousReleaseVersion(path: projectFolder.name)
        let nextReleaseNumber = try selectReleaseNumber(previous: previous, releaseNumber: releaseNumber)
        let releaseNoteSource = try selectReleaseNoteSource(noteSource: noteSource, projectName: projectFolder.name)
        
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
    
    func selectReleaseNoteSource(noteSource: ReleaseNoteSource?, projectName: String) throws -> ReleaseNoteSource {
        if let noteSource {
            return noteSource
        }
        
        let selection = try picker.requiredSingleSelection("How would you like to provide notes for this release?", items: NoteContentType.allCases)
        
        switch selection {
        case .direct:
            let notes = try picker.getRequiredInput(prompt: "Enter your release notes.")
            
            return .direct(notes)
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
    
    func validateAndConfirmNoteFile(_ filePath: String) throws -> ReleaseNoteSource {
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


// MARK: - FormulaInfo
private extension PublishController {
    func loadFormulaInfo(projectName: String) throws -> FormulaInfo {
        let allTaps = try service.loadTaps()
        let selectedTap: HomebrewTap
        
        if let tap = getTap(named: projectName, from: allTaps) {
            selectedTap = tap
        } else {
            selectedTap = try picker.requiredSingleSelection("", items: allTaps)
        }
        
        if let formula = try getFormula(named: projectName, from: selectedTap) {
            return .init(tap: selectedTap, formula: formula)
        }
        
        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectName.yellow) in \(selectedTap.name). Would you like to create a new one?")
        
        let newFormula = createNewFormula()
        
        return .init(tap: selectedTap, formula: newFormula)
    }
    
    func getTap(named name: String, from taps: [HomebrewTap]) -> HomebrewTap? {
        return taps.first { tap in
            return tap.formulas.contains(where: { $0.name.lowercased() == name.lowercased() })
        }
    }
    
    func getFormula(named name: String, from tap: HomebrewTap) throws -> HomebrewFormula? {
        // update the formula's localProjectPath if needed?
        fatalError() // TODO: -
    }
    
    func createNewFormula() -> HomebrewFormula {
        fatalError() // TODO: - may need to save new formula?
    }
}


// MARK: - Build and Archive
private extension PublishController {
    func buildAndArchiveBinaries(formula: HomebrewFormula, skipTesting: Bool = true) throws -> [ArchivedBinary] {
        let testCommand: String? = skipTesting ? nil : nil // TODO: -
        let config = makeConfig(testCommand: testCommand)
        let buildResult = try buildBinary(config: config)
        let binaryPaths = parseBinaryPaths(from: buildResult)
        
        return try BinaryArchiver(shell: shell).createArchives(from: binaryPaths)
    }
    
    func makeConfig(testCommand: String?) -> BuildConfig {
        fatalError() // TODO: -
    }
    
    func buildBinary(config: BuildConfig) throws -> BinaryOutput {
        return try ProjectBuilder(shell: shell, config: config).build()
    }
    
    func parseBinaryPaths(from output: BinaryOutput) -> [String] {
        switch output {
        case .single(let path):
            return [path]
        case .multiple(let binaries):
            return ReleaseArchitecture.allCases.compactMap({ binaries[$0] })
        }
    }
}


// MARK: - Upload Release
private extension PublishController {
    func uploadRelease(folder: any Directory, archivedBinaries: [ArchivedBinary], releaseInfo: ReleaseInfo) throws -> GithubAssetInfo {
        let versionNumber = releaseInfo.versionString
        let assetURLs = try createNewRelease(archivedBinaries: archivedBinaries, releaseInfo: releaseInfo)
        
        try trashReleaseNotes(source: releaseInfo.noteSource)
        
        let primaryAssetURL = assetURLs.first ?? ""

        if archivedBinaries.count == 1 {
            print("GitHub release \(versionNumber) created and binary uploaded to \(primaryAssetURL)")
        } else {
            print("GitHub release \(versionNumber) created and \(archivedBinaries.count) binaries uploaded. First asset at \(primaryAssetURL)")
            if assetURLs.count > 1 {
                print("Additional assets:")
                for (index, url) in assetURLs.dropFirst().enumerated() {
                    print("  Asset \(index + 2): \(url)")
                }
            }
        }
        
        return .init(version: versionNumber, assetURLs: assetURLs)
    }
    
    func trashReleaseNotes(source: ReleaseNoteSource) throws {
        switch source {
        case .filePath(let path):
            if picker.getPermission(prompt: "Would you like to move your release notes file to the trash?") {
                try trashHandler.moveToTrash(at: path)
            }
        default:
            break
        }
    }
    
    func createNewRelease(archivedBinaries: [ArchivedBinary], releaseInfo: ReleaseInfo) throws -> [String] {
        fatalError()
    }
}


// MARK: - Generate Formula Content
private extension PublishController {
    func makeFormulaContent(formula: HomebrewFormula, archivedBinaries: [ArchivedBinary], githubInfo: GithubAssetInfo) throws -> String {
        let formulaName = formula.name
        let details = formula.details
        let homepage = formula.homepage
        let license = formula.license ?? ""
        let version = githubInfo.version
        let assetURLs = githubInfo.assetURLs
        
        if archivedBinaries.count == 1, let sha256 = archivedBinaries.first?.sha256 {
            // Single binary case
            guard let assetURL = assetURLs.first else {
                throw NnexError.missingSha256 // Should create a better error for missing URL
            }
            
            return FormulaContentGenerator.makeFormulaFileContent(
                name: formulaName,
                details: details,
                homepage: homepage,
                license: license,
                version: version,
                assetURL: assetURL,
                sha256: sha256
            )
        } else {
            // Multiple binaries case - match archive paths to determine architecture
            var armArchive: ArchivedBinary?
            var intelArchive: ArchivedBinary?
            
            for archive in archivedBinaries {
                if archive.originalPath.contains("arm64-apple-macosx") {
                    armArchive = archive
                } else if archive.originalPath.contains("x86_64-apple-macosx") {
                    intelArchive = archive
                }
            }

            // Extract URLs - assuming first is ARM, second is Intel when both present
            var armURL: String?
            var intelURL: String?

            if armArchive != nil && intelArchive != nil {
                armURL = assetURLs.count > 0 ? assetURLs[0] : nil
                intelURL = assetURLs.count > 1 ? assetURLs[1] : nil
            } else if armArchive != nil {
                armURL = assetURLs.first
            } else if intelArchive != nil {
                intelURL = assetURLs.first
            }

            return FormulaContentGenerator.makeFormulaFileContent(
                name: formulaName,
                details: details,
                homepage: homepage,
                license: license,
                version: version,
                armURL: armURL,
                armSHA256: armArchive?.sha256,
                intelURL: intelURL,
                intelSHA256: intelArchive?.sha256
            )
        }
    }
}


// MARK: - Publish Formula
private extension PublishController {
    func publishFormula(_ content: String, formulaInfo: FormulaInfo, commitMessage: String?) throws  {
        let fileName = "\(formulaInfo.formula.name).rb"
        let tapFolder = try selectProjectFolder(at: formulaInfo.tap.localPath)
        let formulaFolder = try tapFolder.createSubfolderIfNeeded(named: "Formula")
        
        try deleteOldFormulaFile(from: formulaFolder, fileName: fileName)
        
        let filePath = try formulaFolder.createFile(named: fileName, contents: content)
        
        print("\(fileName) created at \(filePath)")
        
        if let commitMessage = try getHomebrewTapCommitMessage(message: commitMessage) {
            try gitHandler.commitAndPush(message: commitMessage, path: tapFolder.path)
            print("\nPushed changes in \(formulaInfo.tap.name.cyan.underline) to \("GitHub".green)")
        }
    }
    
    func deleteOldFormulaFile(from folder: any Directory, fileName: String) throws {
        if folder.containsFile(named: fileName) {
            print("Found old formula in \(folder.name), preparing to delete")
            try folder.deleteFile(named: fileName)
        }
    }
    
    func getHomebrewTapCommitMessage(message: String?) throws -> String? {
        if let message {
            return message
        }

        guard picker.getPermission(prompt: "\nWould you like to commit and push the tap to \("GitHub".green)?") else {
            return nil
        }

        return try picker.getRequiredInput(prompt: "Enter your commit message.")
    }
}


// MARK: - Dependencies
protocol PublishService {
    func loadTaps() throws -> [HomebrewTap]
}

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
        
        var versionString: String {
            switch nextRelease {
            case .exact(let versionString):
                return versionString.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            case .increment(let component):
                fatalError("what to do with \(component.rawValue)?") // TODO: -
            }
        }
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


// MARK: - Extension Dependencies
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

extension HomebrewTap: DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}

// MARK: - Extension Dependencies
private extension Date {
    /// Formats the date as "M-d-yy" (e.g., "3-24-25").
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: self)
    }
}

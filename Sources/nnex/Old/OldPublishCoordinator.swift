//
//  OldPublishCoordinator.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import NnexKit
import GitShellKit

struct OldPublishCoordinator {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let gitHandler: any GitHandler
    private let dateProvider: any DateProvider
    private let folderBrowser: any DirectoryBrowser
    private let temporaryProtocol: any TemporaryPublishProtocol
    
    init(shell: any NnexShell, picker: any NnexPicker, fileSystem: any FileSystem, gitHandler: any GitHandler, dateProvider: any DateProvider, folderBrowser: any DirectoryBrowser, temporaryProtocol: any TemporaryPublishProtocol) {
        self.shell = shell
        self.picker = picker
        self.fileSystem = fileSystem
        self.gitHandler = gitHandler
        self.dateProvider = dateProvider
        self.folderBrowser = folderBrowser
        self.temporaryProtocol = temporaryProtocol
    }
}


// MARK: -
extension OldPublishCoordinator {
    func publish(projectPath: String?, buildType: BuildType, notes: String?, notesFilePath: String?, commitMessage: String?, skipTests: Bool, version: ReleaseVersionInfo?) throws {
        let projectFolder = try fileSystem.getDirectoryAtPathOrCurrent(path: projectPath)
        
        try verifyPublishRequirements(at: projectFolder.path)
        
        let nextVersionNumber = try selectNextVersionNumber(projectPath: projectFolder.path, versionInfo: version)
        let buildResult = try buildExecutable(projectFolder: projectFolder, buildType: buildType)
        let archives = try makeArchives(result: buildResult)
        let noteSoure = try selectReleaseNoteSource(notes: notes, notesFilePath: notesFilePath, projectName: projectFolder.name)
        let releaseResult = try uploadRelease(archives: archives, executableName: buildResult.executableName, releaseNumber: nextVersionNumber, noteSource: noteSoure, projectPath: projectFolder.path)
        let formula = try getFormula(projectFolder: projectFolder, skipTests: skipTests)
        let formulaContent = try makeFormulaContent(formula: formula, releaseResult: releaseResult, archives: archives)
        
        try publishFormula(formula, content: formulaContent, message: commitMessage)
    }
}


// MARK: - Git Methods
private extension OldPublishCoordinator {
    func verifyPublishRequirements(at path: String) throws {
        try gitHandler.checkForGitHubCLI()
        try ensureNoUncommittedChanges(at: path)
        // TODO: - check for main branch?
    }
    
    func ensureNoUncommittedChanges(at path: String) throws {
        let result = try shell.bash("cd \"\(path)\" && git status --porcelain")
        
        if !result.isEmpty {
            print("""
            There are uncommitted changes in the repository at \(path.yellow):
            
            \(result)
            
            Please commit or stash your changes before publishing.
            """)
            throw PublishExecutionError.uncommittedChanges
        }
    }
}


// MARK: - Next Version Number
private extension OldPublishCoordinator {
    func selectNextVersionNumber(projectPath: String, versionInfo: ReleaseVersionInfo?) throws -> String {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: projectPath)
        let versionInput = try versionInfo ?? getVersionInput(previousVersion: previousVersion)
        let releaseVersionString = try getReleaseVersionString(resolvedVersionInfo: versionInput, projectPath: projectPath)
        
        try handleAutoVersionUpdate(releaseVersionString: releaseVersionString, projectPath: projectPath)
        
        return releaseVersionString
    }
    
    func getVersionInput(previousVersion: String?) throws -> ReleaseVersionInfo {
        var prompt = "\nEnter the version number for this release."

        if let previousVersion {
            prompt.append("\nPrevious release: \(previousVersion.yellow) (To increment, type either \("major".bold), \("minor".bold), or \("patch".bold))")
        } else {
            prompt.append(" (v1.1.0 or 1.1.0)")
        }

        let input = try picker.getRequiredInput(prompt: prompt)

        if let versionPart = ReleaseVersionInfo.VersionPart(string: input) {
            return .increment(versionPart)
        }

        return .version(input)
    }
    
    func handleAutoVersionUpdate(releaseVersionString: String, projectPath: String) throws {
        let autoVersionHandler = AutoVersionHandler(shell: shell, fileSystem: fileSystem)
        
        // Try to detect current version in the executable
        guard let currentVersion = try autoVersionHandler.detectArgumentParserVersion(projectPath: projectPath) else {
            // No version found in source code, nothing to update
            return
        }
        
        // Check if versions differ
        guard autoVersionHandler.shouldUpdateVersion(currentVersion: currentVersion, releaseVersion: releaseVersionString) else {
            // Versions are the same, no update needed
            return
        }
        
        // Ask user if they want to update the version
        let prompt = """
        
        Current executable version: \(currentVersion.yellow)
        Release version: \(releaseVersionString.green)
        
        Would you like to update the version in the source code?
        """
        
        guard picker.getPermission(prompt: prompt) else {
            return
        }
        
        // Update the version in source code
        guard try autoVersionHandler.updateArgumentParserVersion(projectPath: projectPath, newVersion: releaseVersionString) else {
            print("Failed to update version in source code.")
            return
        }
        
        // Commit the version update
        try commitVersionUpdate(version: releaseVersionString, projectPath: projectPath)
        
        print("✅ Updated version to \(releaseVersionString.green) and committed changes.")
    }
    
    func getReleaseVersionString(resolvedVersionInfo: ReleaseVersionInfo, projectPath: String) throws -> String {
        switch resolvedVersionInfo {
        case .version(let versionString):
            return versionString
        case .increment(let versionPart):
            guard let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: projectPath) else {
                throw NnexError.noPreviousVersionToIncrement
            }
            return try VersionHandler.incrementVersion(for: versionPart, path: projectPath, previousVersion: previousVersion)
        }
    }
    
    func commitVersionUpdate(version: String, projectPath: String) throws {
        let commitMessage = "Update version to \(version)"
        try gitHandler.commitAndPush(message: commitMessage, path: projectPath)
    }
}


// MARK: - BuildResult
private extension OldPublishCoordinator {
    func buildExecutable(projectFolder: any Directory, buildType: BuildType) throws -> BuildResult {
        let existingFormula = temporaryProtocol.loadExistingFormula(named: projectFolder.name)
        
        return try temporaryProtocol.buildExecutable(
            projectFolder: projectFolder,
            buildType: buildType,
            clean: true,
            outputLocation: .currentDirectory(buildType),
            extraBuildArgs: existingFormula?.extraBuildArgs ?? [],
            testCommand: existingFormula?.testCommand
        )
    }
}


// MARK: - ReleaseNotes
private extension OldPublishCoordinator {
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
            let fileUtility = ReleaseNotesFileUtility(picker: picker, fileSystem: fileSystem, dateProvider: dateProvider)
            let filePath = try fileUtility.createAndOpenNewNoteFile(projectName: projectName)
            let confirmedPath = try fileUtility.validateAndConfirmNoteFilePath(filePath)
            
            return .filePath(confirmedPath)
        }
    }
}


// MARK: - Release
private extension OldPublishCoordinator {
    func uploadRelease(archives: [ArchivedBinary], executableName: String, releaseNumber: String, noteSource: ReleaseNoteSource, projectPath: String) throws -> ReleaseResult {
        let assetURLs = try createNewRelease(number: releaseNumber, binaries: archives, noteSource: noteSource, projectPath: projectPath)
        
        return .init(assetURLs: assetURLs, versionNumber: releaseNumber, executableName: executableName)
    }
    
    func createNewRelease(number: String, binaries: [ArchivedBinary], noteSource: ReleaseNoteSource, projectPath: String) throws -> [String] {
        let noteInfo: ReleaseNoteInfo
        
        switch noteSource {
        case .exact(let notes):
            noteInfo = .init(content: notes, isFromFile: false)
        case .filePath(let filePath):
            noteInfo = .init(content: filePath, isFromFile: true)
        }
        
        return try gitHandler.createNewRelease(version: number, archivedBinaries: binaries, releaseNoteInfo: noteInfo, path: projectPath)
    }
}


// MARK: - FormulaContent
private extension OldPublishCoordinator {
    func getFormula(projectFolder: any Directory, skipTests: Bool) throws -> HomebrewFormula {
        let allTaps = try temporaryProtocol.loadAllTaps()
        let tap = try getTap(allTaps: allTaps, projectName: projectFolder.name)
        
        if var formula = tap.formulas.first(where: { $0.name.matches(projectFolder.name) }) {
            // Update the formula's localProjectPath if needed
            // this is necessary if formulae have been imported and do not have the correct localProjectPath set
            if formula.localProjectPath.isEmpty || formula.localProjectPath != projectFolder.path {
                formula.localProjectPath = projectFolder.path
                try temporaryProtocol.updateFormula(formula)
            }
           
            return formula
        }
        
        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectFolder.name.yellow) in \(tap.name).\nWould you like to create a new one?")
        
        let newFormula = try createNewFormula(for: projectFolder, skipTests: skipTests)
        try temporaryProtocol.saveNewFormula(newFormula, in: tap)
        return newFormula
    }
    
    func getTap(allTaps: [HomebrewTap], projectName: String) throws -> HomebrewTap {
        if let tap = allTaps.first(where: { tap in
            tap.formulas.contains(where: { $0.name.matches(projectName) })
        }) {
            return tap
        }
        
        return try picker.requiredSingleSelection("\(projectName) does not yet have a formula. Select a tap for this formula.", items: allTaps)
    }
    
    func createNewFormula(for folder: any Directory, skipTests: Bool) throws -> HomebrewFormula {
        let details = try picker.getRequiredInput(prompt: "Enter the description for this formula.")
        let homepage = try gitHandler.getRemoteURL(path: folder.path)
        let license = LicenseDetector.detectLicense(in: folder)
        let testCommand = try getTestCommand(skipTests: skipTests)
        
        return .init(
            name: folder.name,
            details: details,
            homepage: homepage,
            license: license,
            localProjectPath: folder.path,
            uploadType: .tarball,
            testCommand: testCommand,
            extraBuildArgs: []
        )
    }
    
    func getTestCommand(skipTests: Bool) throws -> HomebrewFormula.TestCommand? {
        if skipTests {
            return nil
        }
        
        switch try picker.requiredSingleSelection("How would you like to handle tests?", items: FormulaTestType.allCases) {
        case .custom:
            let command = try picker.getRequiredInput(prompt: "Enter the test command that you would like to use.")
            
            return .custom(command)
        case .packageDefault:
            return .defaultCommand
        case .noTests:
            return nil
        }
    }
    
    func makeFormulaContent(formula: HomebrewFormula, releaseResult: ReleaseResult, archives: [ArchivedBinary]) throws -> String {
        let formulaName = formula.name
        let details = formula.details
        let homepage = formula.homepage
        let license = formula.license
        let assetURLs = releaseResult.assetURLs
        let version = releaseResult.versionNumber
        let installName = releaseResult.executableName
        
        if archives.count == 1 {
            guard let assetURL = assetURLs.first, let sha256 = archives.first?.sha256 else {
                throw NnexError.missingSha256 // Should create a better error for missing URL
            }
            
            return FormulaContentGenerator.makeFormulaFileContent(
                formulaName: formulaName,
                installName: installName,
                details: details,
                homepage: homepage,
                license: license,
                version: version,
                assetURL: assetURL,
                sha256: sha256
            )
        } else {
            var armArchive: ArchivedBinary?
            var intelArchive: ArchivedBinary?
            
            for archive in archives {
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
                formulaName: formulaName,
                installName: installName,
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


// MARK: - Private Methods
private extension OldPublishCoordinator {
    func makeArchives(result: BuildResult) throws -> [ArchivedBinary] {
        let archiver = BinaryArchiver(shell: shell)
        
        switch result.binaryOutput {
        case .single(let path):
            return try archiver.createArchives(from: [path])
        case .multiple(let binaries):
            let binaryPaths = ReleaseArchitecture.allCases.compactMap({ binaries[$0] })
            
            return try archiver.createArchives(from: binaryPaths)
        }
    }
    
    func publishFormula(_ formula: HomebrewFormula, content: String, message: String?) throws {
        let fileName = "\(formula.name).rb"
        let tapFolder = try fileSystem.directory(at: formula.tapLocalPath)
        let formulaFolder = try tapFolder.createSubfolderIfNeeded(named: "Formula")
        
        try deleteOldFormula(named: fileName, from: formulaFolder)
        
        let filePath = try formulaFolder.createFile(named: fileName, contents: content)
        
        print("New formula created at \(filePath)")
        
        if let message = try getMessage(message: message) {
            try gitHandler.commitAndPush(message: message, path: tapFolder.path)
        }
    }
    
    func deleteOldFormula(named name: String, from folder: any Directory) throws {
        if folder.containsFile(named: name) {
            try folder.deleteFile(named: name)
        }
    }
    
    func getMessage(message: String?) throws -> String? {
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
private extension OldPublishCoordinator {
    struct NewReleaseInfo {
        let executableName: String
        let nextReleaseNumber: String
        let noteSource: ReleaseNoteSource
    }
    
    struct ReleaseResult {
        let assetURLs: [String]
        let versionNumber: String
        let executableName: String
    }
    
    enum ReleaseNoteSource {
        case exact(String)
        case filePath(String)
    }
}

extension OldPublishCoordinator {
    enum NoteContentType: CaseIterable {
        case direct, selectFile, fromPath, createFile
    }
}

protocol TemporaryPublishProtocol {
    func loadExistingFormula(named name: String) -> HomebrewFormula?
    func buildExecutable(projectFolder: any Directory, buildType: BuildType, clean: Bool, outputLocation: BuildOutputLocation?, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult
    func updateFormula(_ formula: HomebrewFormula) throws
    func saveNewFormula(_ formula: HomebrewFormula, in tap: HomebrewTap) throws
    func loadAllTaps() throws -> [HomebrewTap]
}

struct TemporaryPublishAdapter: TemporaryPublishProtocol {
    private let context: NnexContext
    private let buildController: BuildController
    private let publishInfoStoreAdatper: PublishInfoStoreAdapter
    
    init(context: NnexContext, buildController: BuildController, publishInfoStoreAdatper: PublishInfoStoreAdapter) {
        self.context = context
        self.buildController = buildController
        self.publishInfoStoreAdatper = publishInfoStoreAdatper
    }
    
    func loadExistingFormula(named name: String) -> HomebrewFormula? {
        return try? loadAllTaps().flatMap({ $0.formulas }).first(where: { $0.name.matches(name) })
    }
    
    func buildExecutable(projectFolder: any Directory, buildType: BuildType, clean: Bool, outputLocation: BuildOutputLocation?, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult {
        return try buildController.buildExecutable(projectFolder: projectFolder, buildType: buildType, clean: clean, outputLocation: outputLocation, extraBuildArgs: extraBuildArgs, testCommand: testCommand)
    }
    
    func updateFormula(_ formula: HomebrewFormula) throws {
        try publishInfoStoreAdatper.updateFormula(formula)
    }
    
    func saveNewFormula(_ formula: HomebrewFormula, in tap: HomebrewTap) throws {
        try publishInfoStoreAdatper.saveNewFormula(formula, in: tap)
    }
    
    func loadAllTaps() throws -> [HomebrewTap] {
        return try publishInfoStoreAdatper.loadTaps()
    }
}

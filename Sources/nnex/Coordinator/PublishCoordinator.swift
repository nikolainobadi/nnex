//
//  PublishCoordinator.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import NnexKit

struct PublishCoordinator {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let gitHandler: any GitHandler
    private let dateProvider: any DateProvider
    private let folderBrowser: any DirectoryBrowser
}


// MARK: -
extension PublishCoordinator {
    func publish(projectPath: String?, buildType: BuildType, notes: String?, notesFilePath: String?, commitMessage: String?, skipTests: Bool) throws {
        let projectFolder = try fileSystem.getDirectoryAtPathOrCurrent(path: projectPath)
        
        try verifyPublishRequirements(at: projectFolder.path)
        
        let nextVersionNumber = try selectNextVersionNumber(projectPath: projectFolder.path)
        let buildResult = try buildExecutable(projectFolder: projectFolder, buildType: buildType)
        let archives = try makeArchives(result: buildResult)
        let releaseInfo = try selectReleaseInfo(executableName: buildResult.executableName, nextVersionNumber: nextVersionNumber, notes: notes, notesFilePath: notesFilePath)
        let releaseResult = try uploadRelease(archives: archives, releaseInfo: releaseInfo, path: projectFolder.path)
        let formula = try getFormula(projectFolder: projectFolder, skipTests: skipTests)
        let formulaContent = try makeFormulaContent(formula: formula, releaseResult: releaseResult, archives: archives)
        
        try publishFormula(formula, content: formulaContent, message: commitMessage)
    }
}


// MARK: - Git Methods
private extension PublishCoordinator {
    func verifyPublishRequirements(at path: String) throws {
        try gitHandler.checkForGitHubCLI()
        try gitHandler.ensureNoUncommittedChanges(at: path)
        // TODO: - check for main branch?
    }
}


// MARK: - Next Version Number
private extension PublishCoordinator {
    func selectNextVersionNumber(projectPath: String) throws -> String {
        let previousVersion = try? gitHandler.getPreviousReleaseVersion(path: projectPath)
        print(previousVersion ?? "no previous version")
        try handleAutoVersionUpdate()
        fatalError() // TODO: -
    }
    
    func handleAutoVersionUpdate() throws {
        // TODO: -
    }
}


// MARK: - BuildResult
private extension PublishCoordinator {
    func buildExecutable(projectFolder: any Directory, buildType: BuildType) throws -> BuildResult {
        let existingFormula = loadExistingFormula(named: projectFolder.name)
        
        return try buildExecutable(
            projectFolder: projectFolder,
            buildType: buildType,
            clean: true,
            outputLocation: .currentDirectory(buildType),
            extraBuildArgs: existingFormula?.extraBuildArgs ?? [],
            testCommand: existingFormula?.testCommand
        )
    }
    
    func loadExistingFormula(named name: String) -> HomebrewFormula? {
        return nil // TODO: -
    }
    
    func buildExecutable(projectFolder: any Directory, buildType: BuildType, clean: Bool, outputLocation: BuildOutputLocation?, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult {
        fatalError() // TODO: -
    }
}


// MARK: - Release
private extension PublishCoordinator {
    func selectReleaseInfo(executableName: String, nextVersionNumber: String, notes: String?, notesFilePath: String?) throws -> NewReleaseInfo {
        let noteSource = try selectReleaseNoteSource(notes: notes, notesFilePath: notesFilePath, projectName: executableName)
        
        return .init(executableName: executableName, noteSource: noteSource)
    }
    
    func uploadRelease(archives: [ArchivedBinary], releaseInfo: NewReleaseInfo, path: String) throws -> ReleaseResult {
        let releaseNumber = try extractReleaseNumber(from: releaseInfo)
        
        let assetURLs = try createNewRelease(number: releaseNumber, binaries: archives, noteSource: releaseInfo.noteSource, projectPath: path)
        
        return .init(assetURLs: assetURLs, versionNumber: releaseNumber, executableName: releaseInfo.executableName)
    }
    
    func extractReleaseNumber(from info: NewReleaseInfo) throws -> String {
        fatalError()
    }
    
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
            
            print("filePath: \(filePath)") // TODO: -
            fatalError()
//            return try fileUtility.validateAndConfirmNoteFile(releaseNotesFile)
        }
    }
    
    func createNewRelease(number: String, binaries: [ArchivedBinary], noteSource: ReleaseNoteSource, projectPath: String) throws -> [String] {
        fatalError()
    }
}


// MARK: - FormulaContent
private extension PublishCoordinator {
    func getFormula(projectFolder: any Directory, skipTests: Bool) throws -> HomebrewFormula {
        let allTaps = try loadAllTaps()
        let tap = try getTap(allTaps: allTaps, projectName: projectFolder.name)
        
        if var formula = tap.formulas.first(where: { $0.name.matches(projectFolder.name) }) {
            // Update the formula's localProjectPath if needed
            // this is necessary if formulae have been imported and do not have the correct localProjectPath set
            if formula.localProjectPath.isEmpty || formula.localProjectPath != projectFolder.path {
                formula.localProjectPath = projectFolder.path
                try updateFormula(formula)
            }
           
            return formula
        }
        
        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectFolder.name.yellow) in \(tap.name).\nWould you like to create a new one?")
        
        let newFormula = try createNewFormula(for: projectFolder, skipTests: skipTests)
        try saveNewFormula(newFormula, in: tap)
        return newFormula
    }
    
    func updateFormula(_ formula: HomebrewFormula) throws {
        fatalError() // TODO: -
    }
    
    func saveNewFormula(_ formula: HomebrewFormula, in tap: HomebrewTap) throws {
        fatalError() // TODO: -
    }
    
    func loadAllTaps() throws -> [HomebrewTap] {
        return [] // TODO: -
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
private extension PublishCoordinator {
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
private extension PublishCoordinator {
    struct NewReleaseInfo {
        let executableName: String
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

extension PublishCoordinator {
    enum NoteContentType: CaseIterable {
        case direct, selectFile, fromPath, createFile
    }
}

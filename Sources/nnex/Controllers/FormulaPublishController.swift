//
//  FormulaPublishController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit

struct FormulaPublishController {
    private let picker: any NnexPicker
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem
    private let store: any PublishInfoStore
    
    init(picker: any NnexPicker, gitHandler: any GitHandler, fileSystem: any FileSystem, store: any PublishInfoStore) {
        self.store = store
        self.picker = picker
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
    }
}


// MARK: -
extension FormulaPublishController {
    func publishFormula(projectFolder: any Directory, info: FormulaPublishInfo, commitMessage: String?) throws {
        let formula = try getFormula(projectFolder: projectFolder, skipTests: true)
        let content = try makeFormulaContent(formula: formula, info: info)
        let tapFolder = try fileSystem.directory(at: formula.tapLocalPath)
        let fileName = "\(formula.name).rb"
        let formulaFolder = try tapFolder.createSubfolderIfNeeded(named: "Formula")
        
        try deleteOldFormula(named: fileName, from: formulaFolder)
        
        let filePath = try formulaFolder.createFile(named: fileName, contents: content)
        
        print("New formula created at \(filePath)")
        
        if let message = try getMessage(message: commitMessage) {
            try gitHandler.commitAndPush(message: message, path: tapFolder.path)
        }
    }
}


// MARK: - Private Methods
private extension FormulaPublishController {
    func getFormula(projectFolder: any Directory, skipTests: Bool) throws -> HomebrewFormula {
        let allTaps = try store.loadTaps()
        let tap = try getTap(allTaps: allTaps, projectName: projectFolder.name)
        
        if var formula = tap.formulas.first(where: { $0.name.matches(projectFolder.name) }) {
            // Update the formula's localProjectPath if needed
            // this is necessary if formulae have been imported and do not have the correct localProjectPath set
            if formula.localProjectPath.isEmpty || formula.localProjectPath != projectFolder.path {
                formula.localProjectPath = projectFolder.path
                try store.updateFormula(formula)
            }
           
            return formula
        }
        
        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectFolder.name.yellow) in \(tap.name).\nWould you like to create a new one?")
        
        let newFormula = try createNewFormula(for: projectFolder, skipTests: skipTests)
        try store.saveNewFormula(newFormula, in: tap)
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
    
    func makeFormulaContent(formula: HomebrewFormula, info: FormulaPublishInfo) throws -> String {
        let formulaName = formula.name
        let details = formula.details
        let homepage = formula.homepage
        let license = formula.license
        let version = info.version
        let archives = info.archives
        let assetURLs = info.assetURLs
        let installName = info.installName
        
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
struct FormulaPublishInfo {
    let version: String
    let installName: String
    let assetURLs: [String]
    let archives: [ArchivedBinary]
}

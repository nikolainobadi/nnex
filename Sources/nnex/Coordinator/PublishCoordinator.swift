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
}


// MARK: -
extension PublishCoordinator {
    func publish(projectPath: String?, buildType: BuildType, commitMessage: String?) throws {
        let projectFolder = try fileSystem.getDirectoryAtPathOrCurrent(path: projectPath)
        
        try verifyPublishRequirements(at: projectFolder.path)
        
        let nextVersionNumber = try selectNextVersionNumber(projectPath: projectFolder.path)
        let archives = try buildReleaseArchives(projectFolder: projectFolder, buildType: buildType)
        let releaseInfo = try selectReleaseInfo(nextVersionNumber: nextVersionNumber)
        let releaseResult = try uploadRelease(archives: archives, releaseInfo: releaseInfo, path: projectFolder.path)
        let formula = try getFormula()
        let formulaContent = try makeFormulaContent(formula: formula, releaseResult: releaseResult)
        
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


// MARK: - Archives
private extension PublishCoordinator {
    func buildReleaseArchives(projectFolder: any Directory, buildType: BuildType) throws -> [ArchivedBinary] {
        let existingFormula = loadExistingFormula(named: projectFolder.name)
        let result = try buildExecutable(
            projectFolder: projectFolder,
            buildType: buildType,
            clean: true,
            outputLocation: .currentDirectory(buildType),
            extraBuildArgs: existingFormula?.extraBuildArgs ?? [],
            testCommand: existingFormula?.testCommand
        )
                     
        return try makeArchives(result: result)
    }
    
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
    
    func loadExistingFormula(named name: String) -> HomebrewFormula? {
        return nil // TODO: -
    }
    
    func buildExecutable(projectFolder: any Directory, buildType: BuildType, clean: Bool, outputLocation: BuildOutputLocation?, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult {
        fatalError() // TODO: -
    }
}


// MARK: - Release
private extension PublishCoordinator {
    func selectReleaseInfo(nextVersionNumber: String) throws -> NewReleaseInfo {
        fatalError() // TODO: -
    }
    
    func uploadRelease(archives: [ArchivedBinary], releaseInfo: NewReleaseInfo, path: String) throws -> ReleaseResult {
        let releaseNumber = try extractReleaseNumber(from: releaseInfo)
        let noteSource = try selectReleaseNoteSource()
        let assetURLs = try createNewRelease(number: releaseNumber, binaries: archives, noteSource: noteSource, projectPath: path)
        
        return .init(assetURLs: assetURLs, versionNumber: releaseNumber, executableName: releaseInfo.executableName)
    }
    
    func extractReleaseNumber(from info: NewReleaseInfo) throws -> String {
        fatalError()
    }
    
    func selectReleaseNoteSource() throws -> ReleaseNoteSource {
        fatalError()
    }
    
    func createNewRelease(number: String, binaries: [ArchivedBinary], noteSource: ReleaseNoteSource, projectPath: String) throws -> [String] {
        fatalError()
    }
}


// MARK: - FormulaContent
private extension PublishCoordinator {
    func getFormula() throws -> HomebrewFormula {
        fatalError() // TODO: -
    }
    
    func makeFormulaContent(formula: HomebrewFormula, releaseResult: ReleaseResult) throws -> String {
        fatalError() // TODO: -
    }
}


// MARK: - Private Methods
private extension PublishCoordinator {
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

// MARK: - BuildExecutable
private extension PublishCoordinator {
//    func buildExecutable(projectFolder: any Directory, buildType: BuildType) throws -> BuildResult {
//        let existingFormula = publishService.loadFormula(named: projectFolder.name)
//
//        return try publishBuilder.buildExecutable(
//            projectFolder: projectFolder,
//            buildType: buildType,
//            clean: true,
//            outputLocation: .currentDirectory(buildType),
//            extraBuildArgs: existingFormula?.extraBuildArgs ?? [],
//            testCommand: existingFormula?.testCommand
//        )
//    }
}


// MARK: - Dependencies
private extension PublishCoordinator {
    struct NewReleaseInfo {
        let executableName: String
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

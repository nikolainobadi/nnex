//
//  PublishManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//


struct PublishManager {
    private let store: any TapStore
    private let fileSystem: any FileSystem
    private let gitHandler: any GitHandler
}


// MARK: - Service
extension PublishManager {
    func publish(request: PublishRequest) throws {
        let fileName = request.formulaFileName
        let tapFolder = try selectTapFolder(at: request.tapFolderPath)
        let formulaFolder = try tapFolder.createSubfolderIfNeeded(named: "Formula")
        let contents = "" // TODO: -
        
        try deleteOldFormulaFile(from: formulaFolder, fileName: fileName)
        _  = try formulaFolder.createFile(named: fileName, contents: contents)
        try gitHandler.commitAndPush(message: request.commitMessage, path: tapFolder.path)
    }

    func availableTaps() throws -> [HomebrewTap] {
        return try store.loadTaps()
    }
    
    func createFormula(named name: String, in tap: HomebrewTap) throws -> HomebrewFormula {
        fatalError() // TODO: -
    }
    
    func resolveFormula(named name: String, in tap: HomebrewTap) throws -> HomebrewFormula? {
        return nil
    }
    
    func makeBuildConfig(projectName: String, projectPath: String, testCommand: TestCommand?) throws -> BuildConfig {
        fatalError() // TODO: -
    }
}


// MARK: - Private Methods
private extension PublishManager {
    func selectTapFolder(at path: String?) throws -> any Directory {
        guard let path else {
            return fileSystem.currentDirectory
        }
        
        return try fileSystem.directory(at: path)
    }
    
    func deleteOldFormulaFile(from folder: any Directory, fileName: String) throws {
        if folder.containsFile(named: fileName) {
            print("Found old formula in \(folder.name), preparing to delete")
            try folder.deleteFile(named: fileName)
        }
    }
}

protocol TapStore {
    func loadTaps() throws -> [HomebrewTap]
}

extension PublishRequest {
    var tapFolderPath: String {
        return tap.localPath
    }
    
    var formulaFileName: String {
        return "" // TODO: -
    }
}

//
//  Publish.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import ArgumentParser

extension Nnex.Brew {
    struct Publish: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Publish an executable to GitHub and Homebrew for distribution."
        )
        
        @Option(name: .long, help: "Path to the project directory where the release will be built. Defaults to the current directory.")
        var path: String?
        
        @Option(name: .shortAndLong, help: "The version number to publish or version part to increment: major, minor, patch.")
        var version: ReleaseVersionInfo?
        
        func run() throws {
            let projectFolder = try getProjectFolder(at: path)
            let (tap, formula) = try getTapAndFormula(projectFolder: projectFolder)
            let binaryInfo = try buildBinary(for: projectFolder)
            let releaseInfo = makeReleaseInfo(folder: projectFolder, binaryInfo: binaryInfo, versionInfo: version)
            let assetURL = try uploadRelease(info: releaseInfo)
            let formulaContent = FormulaContentGenerator.makeFormulaFileContent(formula: formula, assetURL: assetURL, sha256: binaryInfo.sha256)
            
            try publishFormula(formulaContent, formulaName: formula.name, tap: tap)
        }
    }
}


// MARK: - Private Helpers
private extension Nnex.Brew.Publish {
    var shell: Shell {
        return Nnex.makeShell()
    }
    
    var picker: Picker {
        return Nnex.makePicker()
    }
    
    func getProjectFolder(at path: String?) throws -> Folder {
        if let path {
            return try Folder(path: path)
        }
        
        return Folder.current
    }
    
    func getTapAndFormula(projectFolder: Folder) throws -> (SwiftDataTap, SwiftDataFormula) {
        let context = try Nnex.makeContext()
        let loader = PublishInfoLoader(picker: picker, projectFolder: projectFolder, context: context)
        
        return try loader.loadPublishInfo()
    }
    
    func buildBinary(for folder: Folder) throws -> BinaryInfo {
        let builder = ProjectBuilder(shell: shell)
        
        return try builder.buildProject(name: folder.name, path: folder.path)
    }
    
    func makeReleaseInfo(folder: Folder, binaryInfo: BinaryInfo, versionInfo: ReleaseVersionInfo?) -> ReleaseInfo {
        return .init(binaryPath: binaryInfo.path, projectPath: folder.path, versionInfo: versionInfo)
    }
    
    func uploadRelease(info: ReleaseInfo) throws -> String {
        let store = ReleaseStore(shell: shell, picker: picker)
        
        return try store.uploadRelease(info: info)
    }

    func publishFormula(_ content: String, formulaName: String, tap: SwiftDataTap) throws {
        let publisher = FormulaPublisher(shell: shell)
        
        try publisher.publishFormula(content, formulaName: formulaName, tap: tap)
    }
}

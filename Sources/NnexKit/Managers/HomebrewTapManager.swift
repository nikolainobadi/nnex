//
//  HomebrewTapManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import Foundation

public struct HomebrewTapManager {
    private let shell: any NnexShell
    private let store: any HomebrewTapStore
    private let gitHandler: any GitHandler
    
    public init(shell: any NnexShell, store: any HomebrewTapStore, gitHandler: any GitHandler) {
        self.shell = shell
        self.store = store
        self.gitHandler = gitHandler
    }
}


// MARK: - HomebrewTapService
extension HomebrewTapManager: HomebrewTapService {
    public func saveTapListFolderPath(path: String) {
        store.saveTapListFolderPath(path: path)
    }
    
    public func createNewTap(named name: String, details: String, in parentFolder: any Directory, isPrivate: Bool) throws {
        try gitHandler.ghVerification()
        
        let tapFolder = try createTapFolder(named: name, in: parentFolder)
        let remotePath = try createRemoteRepository(folder: tapFolder, details: details, isPrivate: isPrivate)
        
        try store.saveNewTap(.init(folder: tapFolder, remotePath: remotePath), formulas: [])
    }
    
    public func importTap(from folder: any Directory) throws -> HomebrewTapImportResult {
        try gitHandler.ghVerification()
        
        let (tap, warnings) = try makeTap(from: folder)
        
        try store.saveNewTap(tap, formulas: tap.formulas)
        
        return .init(tap: tap, warnings: warnings)
    }
}


// MARK: - Private Methods
private extension HomebrewTapManager {
    func createTapFolder(named name: String, in parentFolder: any Directory) throws -> any Directory {
        let homebrewTapName = name.homebrewTapName
        let tapFolder = try parentFolder.createSubfolderIfNeeded(named: homebrewTapName)
        
        _ = try tapFolder.createSubfolderIfNeeded(named: "Formula")
        
        return tapFolder
    }
    
    func createRemoteRepository(folder: any Directory, details: String, isPrivate: Bool) throws -> String {
        let path = folder.path
        try gitHandler.gitInit(path: path)
        return try gitHandler.remoteRepoInit(tapName: folder.name, path: path, projectDetails: details, visibility: isPrivate ? .privateRepo : .publicRepo)
    }
    
    func makeTap(from folder: any Directory) throws -> (HomebrewTap, [String]) {
        var warnings: [String] = []
        let tapName = folder.name.removingHomebrewPrefix
        let remotePath = try gitHandler.getRemoteURL(path: folder.path)
        let formulas = try loadFormulas(from: folder, warnings: &warnings)
        
        return (.init(name: tapName, localPath: folder.path, remotePath: remotePath, formulas: formulas), warnings)
    }
    
    func loadFormulas(from folder: any Directory, warnings: inout [String]) throws -> [HomebrewFormula] {
        guard let formulaFolder = folder.subdirectories.first(where: { $0.name == "Formula" }) else {
            warnings.append("⚠️ Warning: No 'Formula' folder found in tap directory. Skipping formula import.")
            return []
        }
        
        let formulaFiles = try formulaFolder.findFiles(withExtension: "rb", recursive: false)
        
        return try formulaFiles.compactMap { filePath in
            guard let brewFormula = try decodeBrewFormula(at: filePath, in: formulaFolder, warnings: &warnings) else { return nil }
            
            return makeHomebrewFormula(from: brewFormula)
        }
    }
    
    func decodeBrewFormula(at path: String, in formulaFolder: any Directory, warnings: inout [String]) throws -> DecodableFormulaTemplate? {
        let output = (try? makeBrewOutput(filePath: path, warnings: &warnings)) ?? ""
        
        if !output.isEmpty, !output.contains("⚠️⚠️⚠️"), let data = output.data(using: .utf8) {
            let decoder = JSONDecoder()
            let rootObject = try decoder.decode([String: [DecodableFormulaTemplate]].self, from: data)
            
            return rootObject["formulae"]?.first
        }
        
        let fileName = (path as NSString).lastPathComponent
        let formulaContent = try formulaFolder.readFile(named: fileName)
        let name = extractField(from: formulaContent, pattern: #"class (\w+) < Formula"#) ?? "Unknown"
        let desc = extractField(from: formulaContent, pattern: #"desc\s+"([^"]+)""#) ?? "No description"
        let homepage = extractField(from: formulaContent, pattern: #"homepage\s+"([^"]+)""#) ?? "No homepage"
        let license = extractField(from: formulaContent, pattern: #"license\s+"([^"]+)""#) ?? "No license"
        
        return .init(name: name, desc: desc, homepage: homepage, license: license, versions: .init(stable: nil))
    }
    
    func makeBrewOutput(filePath: String, warnings: inout [String]) throws -> String {
        let brewCheck = try shell.bash("which brew")
        
        if brewCheck.contains("not found") {
            warnings.append("⚠️⚠️⚠️\nHomebrew has NOT been installed. You may want to install it soon...")
            return ""
        }
        
        return try shell.bash("brew info --json=v2 \(filePath)")
    }
    
    func extractField(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        
        return nil
    }
    
    func makeHomebrewFormula(from template: DecodableFormulaTemplate) -> HomebrewFormula {
        let uploadType: HomebrewFormula.FormulaUploadType
        
        if let stable = template.versions.stable, stable.contains(".tar.gz") {
            uploadType = .tarball
        } else {
            uploadType = .binary
        }
        
        return .init(
            name: template.name,
            details: template.desc,
            homepage: template.homepage,
            license: template.license ?? "",
            localProjectPath: "",
            uploadType: uploadType,
            testCommand: nil,
            extraBuildArgs: []
        )
    }
}


// MARK: - Dependencies
public protocol HomebrewTapStore {
    func saveTapListFolderPath(path: String)
    func saveNewTap(_ tap: HomebrewTap, formulas: [HomebrewFormula]) throws
}


// MARK: - Extension Dependencies
private extension HomebrewTap {
    init(folder: any Directory, remotePath: String, formulas: [HomebrewFormula] = []) {
        self.init(name: folder.name, localPath: folder.path, remotePath: remotePath, formulas: formulas)
    }
}

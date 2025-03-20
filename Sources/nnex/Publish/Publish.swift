//
//  Publish.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import SwiftShell
import Foundation
import ArgumentParser

extension Nnex.Brew {
    struct Publish: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Publish an executable to GitHub and Homebrew for distribution."
        )
        
        @Option(name: .long, help: "Path to the project directory where the release will be built. Defaults to the current directory.")
        var path: String?
        
        @Option(name: .shortAndLong, help: "The version number to publish or version part to increment: major, minor, patch.")
        var version: VersionOrIncrement?
        
        func run() throws {
            let projectFolder = try getProjectFolder(at: path)
            let (tap, formula) = try getTapAndFormula(projectFolder: projectFolder)
            let binaryPath = try Nnex.makeBuilder().buildProject(name: projectFolder.name, path: projectFolder.path)
            let sha256 = try getSha256(binaryPath: binaryPath)
            let versionNumber = try getVersionNumber(version, path: projectFolder.path)
            let assetURL = try uploadRelease(binaryPath: binaryPath, versionNumber: versionNumber)
            let formulaContent = FormulaContentGenerator.makeFormulaFileContent(formula: formula, assetURL: assetURL, sha256: sha256)
            
            try publishFormula(formulaContent, formulaName: formula.name, tap: tap)
        }
    }
}

// MARK: - Private Methods
private extension Nnex.Brew.Publish {
    func getProjectFolder(at path: String?) throws -> Folder {
        if let path {
            return try Folder(path: path)
        }
        
        return Folder.current
    }
    
    func getTapAndFormula(projectFolder: Folder) throws -> (SwiftDataTap, SwiftDataFormula) {
        let picker = Nnex.makePicker()
        let context = try Nnex.makeContext()
        let loader = PublishInfoLoader(picker: picker, projectFolder: projectFolder, context: context)
        
        return try loader.loadPublishInfo()
    }
}



// MARK: -
private extension Nnex.Brew.Publish {
    /// returns assetURL for release
    func uploadRelease(binaryPath: String, versionNumber: String) throws -> String {
        let releaseNotes = try Nnex.makePicker().getRequiredInput(.releaseNotes)
        let releaseCommand = """
        gh release create \(versionNumber) \(binaryPath) --title "\(versionNumber)" --notes "\(releaseNotes)"
        """
        
        try SwiftShell.runAndPrint(bash: releaseCommand)
        
        print("GitHub release \(versionNumber) created and binary uploaded.")
        
        return SwiftShell.run(bash: "gh release view --json assets -q '.assets[].url'").stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func getSha256(binaryPath: String) throws -> String {
        let sha256 = SwiftShell.run(bash: "shasum -a 256 \(binaryPath)").stdout.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ").first!
        
        print("sha256: \(sha256)")
        
        return sha256
    }
    
    func publishFormula(_ content: String, formulaName: String, tap: SwiftDataTap) throws {
        let fileName = "\(formulaName).rb"
        let tapFolder = try Folder(path: tap.localPath)
        
        if tapFolder.containsFile(named: fileName) {
            print("\nDeleting old \(formulaName) formula to replace with new formula...")
            try tapFolder.file(named: fileName).delete()
        }
        
        let newFile = try tapFolder.createFile(named: fileName)
        try newFile.write(content)
        
        print("\nSuccessfully created formula at \(newFile.path)")
        
        // TODO: - commit changes to tap folder and push to github
        // maybe I should ask permission and allow a flag to be passed in to 'force' the push or something
    }
}


// MARK: -
private extension Nnex.Brew.Publish {
    func getVersionNumber(_ part: VersionOrIncrement?, path: String) throws -> String {
        guard let part else {
            return try getVersionInput(path: path)
        }
        
        switch part {
        case .version(let number):
            return number
        case .increment(let versionPart):
            return try incrementVersion(versionPart, path: path)
        }
    }
    
    func incrementVersion(_ part: VersionOrIncrement.VersionPart, path: String) throws -> String {
        let previousVersion = SwiftShell.run(bash: "gh release view --json tagName -q '.tagName'").stdout
        
        print("found previous version:", previousVersion)
        
        return try VersionHandler.incrementVersion(for: part, path: path, previousVersion: previousVersion)
    }
    
    func getVersionInput(path: String) throws -> String {
        let input = try Nnex.makePicker().getRequiredInput(.versionNumber)
        
        if let versionPart = VersionOrIncrement.VersionPart(string: input) {
            return try incrementVersion(versionPart, path: path)
        }
        
        guard VersionHandler.isValidVersionNumber(input) else {
            throw VersionError.invalidVersionNumber
        }
        
        return input
    }
}


// MARK: - Dependencies
protocol ProjectBuilder {
    typealias UniversalBinaryPath = String
    func buildProject(name: String, path: String) throws -> UniversalBinaryPath
}

enum VersionHandler {
    static func isValidVersionNumber(_ version: String) -> Bool {
        return version.range(of: #"^v?\d+\.\d+\.\d+$"#, options: .regularExpression) != nil
    }
    
    static func incrementVersion(for part: VersionOrIncrement.VersionPart, path: String, previousVersion: String) throws -> String {
        let cleanedVersion = previousVersion.hasPrefix("v") ? String(previousVersion.dropFirst()) : previousVersion
        var components = cleanedVersion.split(separator: ".").compactMap { Int($0) }

        switch part {
        case .major:
            components[0] += 1
            components[1] = 0
            components[2] = 0
        case .minor:
            components[1] += 1
            components[2] = 0
        case .patch:
            components[2] += 1
        }
        
        return components.map(String.init).joined(separator: ".")
    }
}

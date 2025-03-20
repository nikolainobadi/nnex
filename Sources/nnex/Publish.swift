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
    
    /// returns assetURL for release
    func uploadRelease(binaryPath: String, versionNumber: String) throws -> String {
        let releaseNotes = try Nnex.makePicker().getRequiredInput(.releaseNotes)
        let releaseCommand = """
        gh release create \(versionNumber) \(binaryPath) --title "\(versionNumber)" --notes "\(releaseNotes)" --json assets,url
        """
        
        let output = SwiftShell.run(bash: releaseCommand).stdout
        
        // Parse the output to extract the asset URL
        if let data = output.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let assets = json["assets"] as? [[String: Any]],
           let firstAsset = assets.first,
           let assetUrl = firstAsset["url"] as? String {
            return assetUrl
        }
        
        throw NSError(domain: "UploadRelease", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve binary asset URL."])
    }

    
    func getSha256(binaryPath: String) throws -> String {
        return SwiftShell.run(bash: "shasum -a 256 \(binaryPath)").stdout.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ").first!
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
    
    func getTapAndFormula(projectFolder: Folder) throws -> (SwiftDataTap, SwiftDataFormula) {
        let context = try Nnex.makeContext()
        let tapList = try context.loadTaps()
        
        if tapList.isEmpty {
            throw PickerError.noSavedTaps
        }
        
        guard let tap = tapList.first(where: { tap in
            return tap.formulas.contains(where: { $0.name.lowercased() == projectFolder.name.lowercased() })
        }) else {
            throw PickerError.noTapRegisterdForProject
        }
        
        if let formula = tap.formulas.first(where: { $0.name.lowercased() == projectFolder.name.lowercased() }) {
            return (tap, formula)
        }
        
        let formula = try createNewFormula(for: projectFolder)
        
        try context.saveNewFormula(formula, in: tap)
        
        return (tap, formula)
    }
    
    func createNewFormula(for folder: Folder) throws -> SwiftDataFormula {
        let details = try Nnex.makePicker().getRequiredInput(.formulaDetails)
        let homepage = Nnex.makeRemoteRepoLoader().getGitHubURL(path: folder.path)
        let license = detectLicense(in: folder)
        
        return .init(
            name: folder.name,
            details: details,
            homepage: homepage,
            license: license,
            localProjectPath: folder.path,
            uploadType: .binary
        )
    }
    
    func detectLicense(in folder: Folder) -> String {
        let licenseFiles = ["LICENSE", "LICENSE.md", "COPYING"]
        
        for fileName in licenseFiles {
            if let file = try? folder.file(named: fileName) {
                let content = try? file.readAsString()
                if let content = content {
                    if content.contains("MIT License") {
                        return "MIT"
                    } else if content.contains("Apache License") {
                        return "Apache"
                    } else if content.contains("GNU General Public License") {
                        return "GPL"
                    } else if content.contains("BSD License") {
                        return "BSD"
                    }
                }
            }
        }
        
        return ""
    }
    
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
        guard let previousVersion = Nnex.makeRemoteRepoLoader().getPreviousVersionNumber(path: path) else {
            throw VersionError.noPreviousVersion
        }
        
        return try VersionHandler.incrementVersion(for: part, path: path, previousVersion: previousVersion)
    }
    
    func getVersionInput(path: String) throws -> String {
        let input = try Nnex.makePicker().getRequiredInput(.formulaDetails)
        
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


enum VersionOrIncrement: ExpressibleByArgument {
    case version(String)
    case increment(VersionPart)
    
    enum VersionPart: String, ExpressibleByArgument {
        case major, minor, patch
        
        init?(string: String) {
            self.init(rawValue: string.lowercased())
        }
    }
    
    init?(argument: String) {
        if let versionPart = VersionPart(rawValue: argument) {
            self = .increment(versionPart)
        } else {
            self = .version(argument)
        }
    }
}

enum VersionHandler {
    static func isValidVersionNumber(_ version: String) -> Bool {
        return version.range(of: #"^v?\d+\.\d+\.\d+$"#, options: .regularExpression) != nil
    }
    
    static func incrementVersion(for part: VersionOrIncrement.VersionPart, path: String, previousVersion: String) throws -> String {
        var components = previousVersion.split(separator: ".").compactMap { Int($0) }
        
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

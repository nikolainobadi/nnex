//
//  ImportTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import Foundation
import ArgumentParser

extension Nnex.Brew {
    struct ImportTap: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Select an existing homebrew tap folder on your computer to register."
        )
        
        @Option(name: .shortAndLong, help: "The local path to your Homebrew tap folder. If not provided, you will be prompted to enter it.")
        var path: String?
        
        func run() throws {
            let context = try Nnex.makeContext()
            let path = try path ?? Nnex.makePicker().getRequiredInput(prompt: "Enter the local path to your Homebrew tap folder.")
            let folder = try Folder(path: path)
            let tapName = folder.name.removingHomebrewPrefix
            let formulaFiles = folder.files.filter({ $0.extension == "rb" })
            let remotePath = try Nnex.makeGitHandler().getRemoteURL(path: folder.path)
            let tap = SwiftDataTap(name: tapName, localPath: folder.path, remotePath: remotePath)
            
            var formulas: [SwiftDataFormula] = []
            
            for file in formulaFiles {
                if let brewFormula = try decodeBrewFormula(file) {
                    formulas.append(.init(from: brewFormula))
                    print("decoded \(brewFormula.name), added to tap.")
                }
            }

            try context.saveNewTap(tap, formulas: formulas)
        }
    }
}


// MARK: - Private Methods
private extension Nnex.Brew.ImportTap {
    func decodeBrewFormula(_ file: File) throws -> BrewFormula? {
        let output = try Nnex.makeShell().run("brew info --json=v2 \(file.path)")
        
        if output.isEmpty {
            let formulaContent = try file.readAsString()
            let name = extractField(from: formulaContent, pattern: #"class (\w+) < Formula"#) ?? "Unknown"
            let desc = extractField(from: formulaContent, pattern: #"desc\s+"([^"]+)""#) ?? "No description"
            let homepage = extractField(from: formulaContent, pattern: #"homepage\s+"([^"]+)""#) ?? "No homepage"
            let license = extractField(from: formulaContent, pattern: #"license\s+"([^"]+)""#) ?? "No license"
            
            return .init(name: name, desc: desc, homepage: homepage, license: license, versions: .init(stable: nil))
        } else if let data = output.data(using: .utf8) {
            let decoder = JSONDecoder()
            let rootObject = try decoder.decode([String: [BrewFormula]].self, from: data)
            
            return rootObject["formulae"]?.first
        }
        
        return nil
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
}

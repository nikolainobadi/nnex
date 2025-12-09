//
//  ImportTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import NnexKit
import Foundation
import ArgumentParser

extension Nnex.Brew {
    struct ImportTap: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Select an existing homebrew tap folder on your computer to register.")
        
        @Option(name: .shortAndLong, help: "The local path to your Homebrew tap folder. If not provided, you will be prompted to enter it.")
        var path: String?
        
        func run() throws {
            let picker = Nnex.makePicker()
            let context = try Nnex.makeContext()
            let folder = try selectHomebrewFolder(path: path, picker: picker)
            let tapName = folder.name.removingHomebrewPrefix
            let remotePath = try Nnex.makeGitHandler().getRemoteURL(path: folder.path)

            let formulaFiles: [File]
            if folder.containsSubfolder(named: "Formula") {
                let formulaFolder = try folder.subfolder(named: "Formula")
                formulaFiles = formulaFolder.files.filter({ $0.extension == "rb" })
            } else {
                print("⚠️ Warning: No 'Formula' folder found in tap directory. Skipping formula import.".red)
                formulaFiles = []
            }

            let tap = SwiftHomebrewDataTap(name: tapName, localPath: folder.path, remotePath: remotePath)
            
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
    func selectHomebrewFolder(path: String?, picker: any NnexPicker) throws -> Folder {
        if let path {
            return try Folder(path: path)
        }
        
        return try picker.requiredFolderSelection(prompt: "Select the Homebrew Tap folder you would like to import.")
    }
    /// Decodes a Homebrew formula from a file.
    /// - Parameter file: The file containing the formula.
    /// - Returns: A BrewFormula instance if decoding is successful, or nil otherwise.
    /// - Throws: An error if the decoding process fails.
    func decodeBrewFormula(_ file: File) throws -> BrewFormula? {
        let output: String
        do {
            output = try makeBrewOutput(filePath: file.path)
        } catch {
            output = ""
        }

        if output.isEmpty || output.contains("⚠️⚠️⚠️") {
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
    
    /// Generates Homebrew formula output by running the brew info command.
    /// - Parameter filePath: The path to the formula file.
    /// - Returns: The output from the brew info command.
    /// - Throws: An error if the command execution fails.
    func makeBrewOutput(filePath: String) throws -> String {
        let shell = Nnex.makeShell()
        let brewCheck = try shell.bash("which brew")
        
        if brewCheck.contains("not found") {
            print("⚠️⚠️⚠️\nHomebrew has NOT been installed. You may want to install it soon...".red.bold)
            return ""
        }
        
        return try shell.bash("brew info --json=v2 \(filePath)")
    }
    
    /// Extracts a specific field from the given text using a regular expression pattern.
    /// - Parameters:
    ///   - text: The text to search within.
    ///   - pattern: The regular expression pattern to use for extraction.
    /// - Returns: The extracted field as a string, or nil if not found.
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

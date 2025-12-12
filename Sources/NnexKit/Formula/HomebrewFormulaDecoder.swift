//
//  HomebrewFormulaDecoder.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/30/25.
//

import Foundation

struct HomebrewFormulaDecoder {
    private let shell: any NnexShell
    
    init(shell: any NnexShell) {
        self.shell = shell
    }
}


// MARK: - Actions
extension HomebrewFormulaDecoder {
    func decodeFormulas(in tapFolder: any Directory) throws -> ([HomebrewFormula], [String]) {
        guard let formulaFolder = tapFolder.subdirectories.first(where: { $0.name == "Formula" }) else {
            return ([], ["⚠️ Warning: No 'Formula' folder found in tap directory. Skipping formula import."])
        }
        
        var warnings: [String] = []
        let formulaFiles = try formulaFolder.findFiles(withExtension: "rb", recursive: false)
        let formulas: [HomebrewFormula] = try formulaFiles.compactMap { filePath in
            guard let brewFormula = try decodeBrewFormula(at: filePath, in: formulaFolder, warnings: &warnings) else {
                return nil
            }
            
            return makeHomebrewFormula(from: brewFormula, tapLocalPath: tapFolder.path)
        }
        
        return (formulas, warnings)
    }
}


// MARK: - Helpers
private extension HomebrewFormulaDecoder {
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
    
    func makeHomebrewFormula(from template: DecodableFormulaTemplate, tapLocalPath: String) -> HomebrewFormula {
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
            extraBuildArgs: [],
            tapLocalPath: tapLocalPath
        )
    }
}

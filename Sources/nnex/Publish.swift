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
        
        enum VersionPart: String, ExpressibleByArgument {
            case major, minor, patch
        }
        
        @Option(name: .shortAndLong, help: "")
        var tap: String?
        
        @Option(name: .shortAndLong, help: "")
        var formula: String?
        
        @Option(name: .long, help: "Path to the project directory where the release will be built. Defaults to the current directory.")
        var path: String?
        
        @Option(name: .shortAndLong, help: "The version number to publish.")
        var version: String?
        
        @Option(name: .long, help: "Specifies which part of the version to auto-increment: major, minor, patch.")
        var increment: VersionPart?
        
        func run() throws {
            let tap = try selectTap(tap)
            let formula = try selectFormula(formula, from: tap)
            let projectFolder = try getProjectFolder(at: path)
            let binaryPath = try Nnex.makeBuilder().buildProject(name: projectFolder.name, path: projectFolder.path)
            let file = try File(path: binaryPath)
            
            print("binary file path for formula \(formula.name): ", file.path)
        }
    }
}

// MARK: - Private Methods
private extension Nnex.Brew.Publish {
    func selectTap(_ tap: String?) throws -> SwiftDataTap {
        let context = try Nnex.makeContext()
        let tapList = try context.loadTaps()
        
        if tapList.isEmpty {
            throw PickerError.noSavedTaps
        }
        
        if let tap, let selectedTap = tapList.first(where: { $0.name.lowercased() == tap.lowercased() }) {
            return selectedTap
        }
        
        return try Nnex.makePicker().requiredSingleSelection(title: "Select a tap.", items: tapList)
    }
    
    func selectFormula(_ formula: String?, from tap: SwiftDataTap) throws -> SwiftDataFormula {
        if let formula, let selection = tap.formulas.first(where: { $0.name.lowercased() == formula.lowercased() }) {
            return selection
        }
        
        return try Nnex.makePicker().requiredSingleSelection(title: "Select a formula", items: tap.formulas)
    }
    
    func getProjectFolder(at path: String?) throws -> Folder {
        if let path {
            return try Folder(path: path)
        }
        
        return Folder.current
    }
}


// MARK: - Dependencies
protocol ProjectBuilder {
    typealias UniversalBinaryPath = String
    func buildProject(name: String, path: String) throws -> UniversalBinaryPath
}

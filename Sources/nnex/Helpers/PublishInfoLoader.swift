//
//  PublishInfoLoader.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files
import NnexKit

/// Loads publish information, including taps and formulas, for the publishing process.
struct PublishInfoLoader {
    private let shell: Shell
    private let picker: Picker
    private let projectFolder: Folder
    private let gitHandler: GitHandler
    private let context: NnexContext
    private let skipTests: Bool
    
    /// Initializes a new instance of PublishInfoLoader.
    /// - Parameters:
    ///   - shell: The shell instance for executing commands.
    ///   - picker: The picker instance for user input.
    ///   - projectFolder: The folder containing the project to be published.
    ///   - context: The context for loading saved taps and formulas.
    ///   - gitHandler: The Git handler for managing repository operations.
    init(shell: Shell, picker: Picker, projectFolder: Folder, context: NnexContext, gitHandler: GitHandler, skipTests: Bool) {
        self.shell = shell
        self.picker = picker
        self.projectFolder = projectFolder
        self.context = context
        self.gitHandler = gitHandler
        self.skipTests = skipTests
    }
}


// MARK: - Load
extension PublishInfoLoader {
    /// Loads the publishing information, including the selected tap and formula.
    /// - Returns: A tuple containing the selected tap and formula.
    /// - Throws: An error if the loading process fails.
    func loadPublishInfo() throws -> (SwiftDataTap, SwiftDataFormula) {
        let allTaps = try context.loadTaps()
        let tap = try getTap(allTaps: allTaps) ?? picker.requiredSingleSelection(
            title: "\(projectFolder.name) does not yet have a formula. Select a tap for this formula.",
            items: allTaps
        )
        
        if let formula = tap.formulas.first(where: { $0.name.lowercased() == projectFolder.name.lowercased() }) {
            return (tap, formula)
        }
        
        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectFolder.name.yellow) in \(tap.name).\nWould you like to create a new one?")
        
        let newFormula = try createNewFormula(for: projectFolder)
        try context.saveNewFormula(newFormula, in: tap)
        
        return (tap, newFormula)
    }
}


// MARK: - Private Methods
private extension PublishInfoLoader {
    /// Retrieves an existing tap matching the project name, if available.
    /// - Parameter allTaps: An array of available taps.
    /// - Returns: A SwiftDataTap instance if a matching tap is found, or nil otherwise.
    func getTap(allTaps: [SwiftDataTap]) -> SwiftDataTap? {
        return allTaps.first { tap in
            return tap.formulas.contains(where: { $0.name.lowercased() == projectFolder.name.lowercased() })
        }
    }
    
    /// Creates a new formula for the given project folder.
    /// - Parameter folder: The project folder for which to create a formula.
    /// - Returns: A SwiftDataFormula instance representing the created formula.
    /// - Throws: An error if the creation process fails.
    func createNewFormula(for folder: Folder) throws -> SwiftDataFormula {
        let name = try getExecutableName()
        let details = try picker.getRequiredInput(prompt: "Enter the description for this formula.")
        let homepage = try gitHandler.getRemoteURL(path: folder.path)
        let license = LicenseDetector.detectLicense(in: folder)
        let testCommand = try getTestCommand()
        let extraArgs = getExtraArgs()
        
        return .init(
            name: name,
            details: details,
            homepage: homepage,
            license: license,
            localProjectPath: folder.path,
            uploadType: .binary,
            testCommand: testCommand,
            extraBuildArgs: extraArgs
        )
    }
    
    func getExecutableName() throws -> String {
        let content = try projectFolder.file(named: "Package.swift").readAsString()
        let names = try ExecutableDetector.getExecutables(packageManifestContent: content)
        
        guard names.count > 1 else {
            return names.first!
        }
        
        return try picker.requiredSingleSelection(title: "Which executable would you like to build?", items: names)
    }
    
    func getTestCommand() throws -> TestCommand? {
        if skipTests {
            return nil
        }
        
        switch try picker.requiredSingleSelection(title: "How would you like to handle tests?", items: FormulaTestType.allCases) {
        case .custom:
            let command = try picker.getRequiredInput(prompt: "Enter the test command that you would like to use.")
            
            return .custom(command)
        case .packageDefault:
            return .defaultCommand
        case .noTests:
            return nil
        }
    }
    
    /// Retrieves additional arguments for the formula.
    /// - Returns: An array of extra arguments as strings.
    func getExtraArgs() -> [String] {
        // TODO: - 
        return []
    }
}


// MARK: - Extension Dependenies
enum BuildError: Error {
    case missingExecutable
}

enum FormulaTestType: CaseIterable {
    case custom, packageDefault, noTests
}

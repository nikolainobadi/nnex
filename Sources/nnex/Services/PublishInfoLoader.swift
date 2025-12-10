//
//  PublishInfoLoader.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files
import NnexKit

struct PublishInfoLoader {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let projectFolder: Folder
    private let gitHandler: any GitHandler
    private let context: NnexContext
    private let skipTests: Bool
    
    /// Initializes a new instance of PublishInfoLoader.
    /// - Parameters:
    ///   - shell: The shell instance for executing commands.
    ///   - picker: The picker instance for user input.
    ///   - projectFolder: The folder containing the project to be published.
    ///   - context: The context for loading saved taps and formulas.
    ///   - gitHandler: The Git handler for managing repository operations.
    init(shell: any NnexShell, picker: any NnexPicker, projectFolder: Folder, context: NnexContext, gitHandler: any GitHandler, skipTests: Bool) {
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
    func loadPublishInfo() throws -> (SwiftDataHomebrewTap, SwiftDataFormula) {
        let allTaps = try context.loadTaps()
        let tap = try getTap(allTaps: allTaps) ?? picker.requiredSingleSelection("\(projectFolder.name) does not yet have a formula. Select a tap for this formula.", items: allTaps)
        
        if let formula = tap.formulas.first(where: { $0.name.lowercased() == projectFolder.name.lowercased() }) {
            // Update the formula's localProjectPath if needed
            if formula.localProjectPath.isEmpty || formula.localProjectPath != projectFolder.path {
                formula.localProjectPath = projectFolder.path
                try context.saveChanges()
            }
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
    func getTap(allTaps: [SwiftDataHomebrewTap]) -> SwiftDataHomebrewTap? {
        return allTaps.first { tap in
            return tap.formulas.contains(where: { $0.name.lowercased() == projectFolder.name.lowercased() })
        }
    }
    
    /// Creates a new formula for the given project folder.
    /// - Parameter folder: The project folder for which to create a formula.
    /// - Returns: A SwiftDataFormula instance representing the created formula.
    /// - Throws: An error if the creation process fails.
    func createNewFormula(for folder: Folder) throws -> SwiftDataFormula {
        fatalError() // TODO: - 
//        let name = try getExecutableName()
//        let details = try picker.getRequiredInput(prompt: "Enter the description for this formula.")
//        let homepage = try gitHandler.getRemoteURL(path: folder.path)
//        let license = LicenseDetector.detectLicense(in: folder)
//        let testCommand = try getTestCommand()
//        let extraArgs = getExtraArgs()
//        
//        return .init(
//            name: name,
//            details: details,
//            homepage: homepage,
//            license: license,
//            localProjectPath: folder.path,
//            uploadType: .binary,
//            testCommand: testCommand,
//            extraBuildArgs: extraArgs
//        )
    }
    
    /// Retrieves the name of the executable from the package manifest.
    /// - Returns: The executable name as a string.
    /// - Throws: An error if the executable name cannot be determined.
    func getExecutableName() throws -> String {
        let content = try projectFolder.file(named: "Package.swift").readAsString()
        let names = try ExecutableDetector.getExecutables(packageManifestContent: content)
        
        guard names.count > 1 else {
            return names.first!
        }
        
        return try picker.requiredSingleSelection("Which executable would you like to build?", items: names)
    }
    
    /// Retrieves the test command based on user input or configuration.
    /// - Returns: A `TestCommand` instance if tests are to be run, or `nil` if tests are skipped.
    /// - Throws: An error if the test command cannot be determined.
    func getTestCommand() throws -> TestCommand? {
        if skipTests {
            return nil
        }
        
        switch try picker.requiredSingleSelection("How would you like to handle tests?", items: FormulaTestType.allCases) {
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
enum FormulaTestType: CaseIterable {
    case custom, packageDefault, noTests
}

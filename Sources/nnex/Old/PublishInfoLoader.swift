////
////  PublishInfoLoader.swift
////  nnex
////
////  Created by Nikolai Nobadi on 3/20/25.
////
//
//import NnexKit
//
//struct PublishInfoLoader {
//    private let shell: any NnexShell
//    private let picker: any NnexPicker
//    private let gitHandler: any GitHandler
//    private let store: any PublishInfoStore
//    private let projectFolder: any Directory
//    private let skipTests: Bool
//    
//    init(
//        shell: any NnexShell,
//        picker: any NnexPicker,
//        gitHandler: any GitHandler,
//        store: any PublishInfoStore,
//        projectFolder: any Directory,
//        skipTests: Bool
//    ) {
//        self.store = store
//        self.shell = shell
//        self.picker = picker
//        self.projectFolder = projectFolder
//        self.gitHandler = gitHandler
//        self.skipTests = skipTests
//    }
//}
//
//
//// MARK: - Load
//extension PublishInfoLoader {
//    /// Loads the publishing information, including the selected tap and formula.
//    /// - Returns: A tuple containing the selected tap and formula.
//    /// - Throws: An error if the loading process fails.
//    func loadPublishInfo() throws -> (HomebrewTap, HomebrewFormula) {
//        let allTaps = try store.loadTaps()
//        let tap = try getTap(allTaps: allTaps)
//        if var formula = tap.formulas.first(where: { $0.name.matches(projectFolder.name) }) {
//            // Update the formula's localProjectPath if needed
//            // this is necessary if formulae have been imported and do not have the correct localProjectPath set
//            if formula.localProjectPath.isEmpty || formula.localProjectPath != projectFolder.path {
//                formula.localProjectPath = projectFolder.path
//                try store.updateFormula(formula)
//            }
//            return (tap, formula)
//        }
//        
//        try picker.requiredPermission(prompt: "Could not find existing formula for \(projectFolder.name.yellow) in \(tap.name).\nWould you like to create a new one?")
//        
//        let newFormula = try createNewFormula(for: projectFolder)
//        try store.saveNewFormula(newFormula, in: tap)
//
//        return (tap, newFormula)
//    }
//}
//
//
//// MARK: - Private Methods
//private extension PublishInfoLoader {
//    /// Retrieves an existing tap matching the project name, if available.
//    /// - Parameter allTaps: An array of available taps.
//    /// - Returns: A SwiftDataHomebrewTap instance if a matching tap is found, or nil otherwise.
//    func getTap(allTaps: [HomebrewTap]) throws -> HomebrewTap {
//        if let tap = allTaps.first(where: { tap in
//            tap.formulas.contains(where: { $0.name.matches(projectFolder.name) })
//        }) {
//            return tap
//        }
//        
//        return try picker.requiredSingleSelection("\(projectFolder.name) does not yet have a formula. Select a tap for this formula.", items: allTaps)
//    }
//    
//    /// Creates a new formula for the given project folder.
//    /// - Parameter folder: The project folder for which to create a formula.
//    /// - Returns: A SwiftDataHomebrewFormula instance representing the created formula.
//    /// - Throws: An error if the creation process fails.
//    func createNewFormula(for folder: any Directory) throws -> HomebrewFormula {
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
//            uploadType: .tarball,
//            testCommand: testCommand,
//            extraBuildArgs: extraArgs
//        )
//    }
//    
//    /// Retrieves the name of the executable from the package manifest.
//    /// - Returns: The executable name as a string.
//    /// - Throws: An error if the executable name cannot be determined.
//    func getExecutableName() throws -> String {
//        let names = try ExecutableNameResolver.getExecutableNames(from: projectFolder)
//        
//        guard names.count > 1 else {
//            return names.first!
//        }
//        
//        return try picker.requiredSingleSelection("Which executable would you like to build?", items: names)
//    }
//    
//    /// Retrieves the test command based on user input or configuration.
//    /// - Returns: A `TestCommand` instance if tests are to be run, or `nil` if tests are skipped.
//    /// - Throws: An error if the test command cannot be determined.
//    func getTestCommand() throws -> HomebrewFormula.TestCommand? {
//        if skipTests {
//            return nil
//        }
//        
//        switch try picker.requiredSingleSelection("How would you like to handle tests?", items: FormulaTestType.allCases) {
//        case .custom:
//            let command = try picker.getRequiredInput(prompt: "Enter the test command that you would like to use.")
//            
//            return .custom(command)
//        case .packageDefault:
//            return .defaultCommand
//        case .noTests:
//            return nil
//        }
//    }
//    
//    /// Retrieves additional arguments for the formula.
//    /// - Returns: An array of extra arguments as strings.
//    func getExtraArgs() -> [String] {
//        // TODO: - 
//        return []
//    }
//}
//
//
//// MARK: - Extension Dependenies


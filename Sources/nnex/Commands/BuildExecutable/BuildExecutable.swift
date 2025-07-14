//
//  BuildExecutable.swift
//  nnex
//
//  Created by Nikolai Nobadi on 4/21/25.
//

import Files
import NnexKit
import ArgumentParser
import Foundation
import SwiftPicker

// MARK: - BuildOutputLocation
enum BuildOutputLocation {
    case currentDirectory(BuildType)
    case desktop
    case custom(String)
}

extension BuildOutputLocation: DisplayablePickerItem {
    var displayName: String {
        switch self {
        case .currentDirectory(let buildType):
            return "Current directory (.build/\(buildType.rawValue))"
        case .desktop:
            return "Desktop"
        case .custom:
            return "Custom location..."
        }
    }
}

extension Nnex {
    struct Build: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Builds the project and outputs the location of the newly built binary."
        )
        
        @Option(name: .shortAndLong, help: "Path to the project directory where the release will be built. Defaults to the current directory.")
        var path: String?
        
        @Option(name: .shortAndLong, help: "The build type to set. Options: \(BuildType.allCases.map(\.rawValue).joined(separator: ", "))")
        var buildType: BuildType?
        
        @Flag(name: .shortAndLong, help: "Open the built binary in Finder after building.")
        var openInFinder: Bool = false
        
        @Flag(inversion: .prefixedNo, help: "Clean the build directory before building. Defaults to true.")
        var clean: Bool = true
        
        func run() throws {
            let shell = Nnex.makeShell()
            let picker = Nnex.makePicker()
            let context = try Nnex.makeContext()
            let buildType = buildType ?? context.loadDefaultBuildType()
            let projectFolder = try Nnex.Brew.getProjectFolder(at: path)
            let executableName = try getExecutableName(for: projectFolder)
            
            // Select output location
            let outputLocation = try selectOutputLocation(buildType: buildType, picker: picker)
            
            let config = BuildConfig(projectName: executableName, projectPath: projectFolder.path, buildType: buildType, extraBuildArgs: [], skipClean: !clean, testCommand: nil)
            let builder = ProjectBuilder(shell: shell, config: config)
            let binaryInfo = try builder.build()
            
            // Copy binary to selected location if different from default
            let finalPath = try copyBinaryToLocation(binaryInfo: binaryInfo, outputLocation: outputLocation, executableName: executableName, shell: shell)
            
            print("New binary was built at \(finalPath)")
            
            if openInFinder {
                try shell.runAndPrint("open -R \(finalPath)")
            }
        }
    }
}

extension Nnex.Build {
    func getExecutableName(for projectFolder: Folder) throws -> String {
        let picker = Nnex.makePicker()
        let content = try projectFolder.file(named: "Package.swift").readAsString()
        let names = try ExecutableDetector.getExecutables(packageManifestContent: content)
        
        guard names.count > 1 else {
            return names.first!
        }
        
        return try picker.requiredSingleSelection(title: "Which executable would you like to build?", items: names)
    }
    
    func selectOutputLocation(buildType: BuildType, picker: Picker) throws -> BuildOutputLocation {
        let options: [BuildOutputLocation] = [
            .currentDirectory(buildType),
            .desktop,
            .custom("")
        ]
        
        let selection = try picker.requiredSingleSelection(title: "Where would you like to place the built binary?", items: options)
        
        // Handle custom location input
        if case .custom = selection {
            return try handleCustomLocationInput(picker: picker)
        }
        
        return selection
    }
    
    func handleCustomLocationInput(picker: Picker) throws -> BuildOutputLocation {
        let parentPath = try picker.getRequiredInput(prompt: "Enter the path to the parent directory where you want to place the binary:")
        
        // Validate the parent path exists
        guard let parentFolder = try? Folder(path: parentPath) else {
            throw NSError(domain: "BuildError", code: 1, userInfo: [NSLocalizedDescriptionKey: "The specified path '\(parentPath)' does not exist or is not accessible."])
        }
        
        // Confirm the final location
        let confirmed = picker.getPermission(prompt: "The binary will be placed at: \(parentFolder.path). Continue?")
        guard confirmed else {
            throw NSError(domain: "BuildError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Build cancelled by user."])
        }
        
        return .custom(parentFolder.path)
    }
    
    func copyBinaryToLocation(binaryInfo: BinaryInfo, outputLocation: BuildOutputLocation, executableName: String, shell: Shell) throws -> String {
        switch outputLocation {
        case .currentDirectory:
            // Binary is already in the correct location
            return binaryInfo.path
            
        case .desktop:
            let desktop = try Folder.home.subfolder(named: "Desktop")
            let destinationPath = desktop.path + "/" + executableName
            try shell.runAndPrint("cp \"\(binaryInfo.path)\" \"\(destinationPath)\"")
            return destinationPath
            
        case .custom(let parentPath):
            let destinationPath = parentPath + "/" + executableName
            try shell.runAndPrint("cp \"\(binaryInfo.path)\" \"\(destinationPath)\"")
            return destinationPath
        }
    }
}

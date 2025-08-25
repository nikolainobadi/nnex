//
//  BuildExecutable.swift
//  nnex
//
//  Created by Nikolai Nobadi on 4/21/25.
//

import Files
import NnexKit
import NnShellKit
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
//            let shell = Nnex.makeShell()
//            let picker = Nnex.makePicker()
//            let context = try Nnex.makeContext()
//            let buildType = buildType ?? context.loadDefaultBuildType()
//            let projectFolder = try Nnex.Brew.getProjectFolder(at: path)
//            let executableName = try getExecutableName(for: projectFolder)
//            
//            // Select output location
//            let outputLocation = try selectOutputLocation(buildType: buildType, picker: picker)
//            
//            let config = BuildConfig(projectName: executableName, projectPath: projectFolder.path, buildType: buildType, extraBuildArgs: [], skipClean: !clean, testCommand: nil)
//            let builder = ProjectBuilder(shell: shell, config: config)
//            let binaryInfo = try builder.build()
            
            // TODO: -
            // Copy binary to selected location if different from default
//            let finalPath = try copyBinaryToLocation(binaryInfo: binaryInfo, outputLocation: outputLocation, executableName: executableName, shell: shell)
//            
//            print("New binary was built at \(finalPath)")
//            
//            if openInFinder {
//                _ = try shell.bash("open -R \(finalPath)")
//            }
        }
    }
}

extension Nnex.Build {
    func getExecutableName(for projectFolder: Folder) throws -> String {
        let picker = Nnex.makePicker()
        
        // Check if Package.swift exists
        guard projectFolder.containsFile(named: "Package.swift") else {
            throw NSError(domain: "BuildError", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "No Package.swift file found in '\(projectFolder.path)'. This does not appear to be a Swift package."
            ])
        }
        
        // Read and validate Package.swift content
        let content: String
        do {
            content = try projectFolder.file(named: "Package.swift").readAsString()
        } catch {
            throw NSError(domain: "BuildError", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Failed to read Package.swift file: \(error.localizedDescription)"
            ])
        }
        
        // Validate content is not empty
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "BuildError", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "Package.swift file is empty or contains only whitespace."
            ])
        }
        
        // Extract executable names
        let names: [String]
        do {
            names = try ExecutableDetector.getExecutables(packageManifestContent: content)
        } catch {
            throw NSError(domain: "BuildError", code: 6, userInfo: [
                NSLocalizedDescriptionKey: "Failed to parse executable targets from Package.swift: \(error.localizedDescription)"
            ])
        }
        
        // Validate that at least one executable was found
        guard !names.isEmpty else {
            throw NSError(domain: "BuildError", code: 7, userInfo: [
                NSLocalizedDescriptionKey: "No executable targets found in Package.swift. Make sure your package defines at least one executable product."
            ])
        }
        
        // Return single executable or prompt for selection
        guard names.count > 1 else {
            return names.first!
        }
        
        // Handle multiple executables
        do {
            return try picker.requiredSingleSelection(title: "Which executable would you like to build?", items: names)
        } catch {
            throw NSError(domain: "BuildError", code: 8, userInfo: [
                NSLocalizedDescriptionKey: "Failed to select executable: \(error.localizedDescription)"
            ])
        }
    }
    
    func selectOutputLocation(buildType: BuildType, picker: NnexPicker) throws -> BuildOutputLocation {
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
    
    func handleCustomLocationInput(picker: NnexPicker) throws -> BuildOutputLocation {
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
    
    func copyBinaryToLocation(binaryInfo: BinaryInfo, outputLocation: BuildOutputLocation, executableName: String, shell: any Shell) throws -> String {
        switch outputLocation {
        case .currentDirectory:
            // Binary is already in the correct location
            return binaryInfo.path
            
        case .desktop:
            let desktop = try Folder.home.subfolder(named: "Desktop")
            let destinationPath = desktop.path + "/" + executableName
            _ = try shell.bash("cp \"\(binaryInfo.path)\" \"\(destinationPath)\"")
            return destinationPath
            
        case .custom(let parentPath):
            let destinationPath = parentPath + "/" + executableName
            _ = try shell.bash("cp \"\(binaryInfo.path)\" \"\(destinationPath)\"")
            return destinationPath
        }
    }
}

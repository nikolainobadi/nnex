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
            let binaryOutput = try builder.build()
            
            // Copy binary to selected location if different from default
            let finalPaths = try copyBinaryToLocation(binaryOutput: binaryOutput, outputLocation: outputLocation, executableName: executableName, shell: shell)
            
            switch finalPaths {
            case .single(let binaryInfo):
                print("New binary was built at \(binaryInfo.path)")
                if openInFinder {
                    _ = try shell.bash("open -R \(binaryInfo.path)")
                }
            case .multiple(let binaries):
                print("Universal binary built:")
                for (arch, binaryInfo) in binaries {
                    print("  \(arch.name): \(binaryInfo.path)")
                }
                if openInFinder, let firstBinary = binaries.values.first {
                    _ = try shell.bash("open -R \(firstBinary.path)")
                }
            }
        }
    }
}

extension Nnex.Build {
    func getExecutableName(for projectFolder: Folder) throws -> String {
        let picker = Nnex.makePicker()
        let resolver = ExecutableNameResolver()
        let names = try resolver.getExecutableNames(from: projectFolder)
        
        guard names.count > 1 else {
            return names.first!
        }
        
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
    
    func copyBinaryToLocation(binaryOutput: BinaryOutput, outputLocation: BuildOutputLocation, executableName: String, shell: any Shell) throws -> BinaryOutput {
        switch outputLocation {
        case .currentDirectory:
            // Binary is already in the correct location
            return binaryOutput
            
        case .desktop:
            let desktop = try Folder.home.subfolder(named: "Desktop")
            return try copyToDestination(binaryOutput: binaryOutput, destinationPath: desktop.path, executableName: executableName, shell: shell)
            
        case .custom(let parentPath):
            return try copyToDestination(binaryOutput: binaryOutput, destinationPath: parentPath, executableName: executableName, shell: shell)
        }
    }
    
    private func copyToDestination(binaryOutput: BinaryOutput, destinationPath: String, executableName: String, shell: any Shell) throws -> BinaryOutput {
        switch binaryOutput {
        case .single(let binaryInfo):
            let finalPath = destinationPath + "/" + executableName
            _ = try shell.bash("cp \"\(binaryInfo.path)\" \"\(finalPath)\"")
            return .single(.init(path: finalPath))
            
        case .multiple(let binaries):
            var results: [ReleaseArchitecture: BinaryInfo] = [:]
            for (arch, binaryInfo) in binaries {
                let finalPath = destinationPath + "/" + executableName + "-\(arch.name)"
                _ = try shell.bash("cp \"\(binaryInfo.path)\" \"\(finalPath)\"")
                results[arch] = .init(path: finalPath)
            }
            return .multiple(results)
        }
    }
}

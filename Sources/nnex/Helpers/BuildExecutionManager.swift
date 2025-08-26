//
//  BuildExecutionManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Files
import NnexKit
import NnShellKit
import Foundation

struct BuildExecutionManager {
    private let shell: any Shell
    private let picker: NnexPicker
    private let context: NnexContext
    
    init(shell: any Shell, picker: NnexPicker, context: NnexContext) {
        self.shell = shell
        self.picker = picker
        self.context = context
    }
    
    func executeBuild(projectPath: String?, buildType: BuildType?, clean: Bool, openInFinder: Bool) throws {
        let buildType = buildType ?? context.loadDefaultBuildType()
        let projectFolder = try Nnex.Brew.getProjectFolder(at: projectPath)
        let executableName = try getExecutableName(for: projectFolder)
        
        let outputLocation = try selectOutputLocation(buildType: buildType)
        let config = BuildConfig(projectName: executableName, projectPath: projectFolder.path, buildType: buildType, extraBuildArgs: [], skipClean: !clean, testCommand: nil)
        let builder = ProjectBuilder(shell: shell, config: config)
        let binaryOutput = try builder.build()
        
        let finalPaths = try copyBinaryToLocation(binaryOutput: binaryOutput, outputLocation: outputLocation, executableName: executableName)
        
        displayBuildResult(finalPaths, openInFinder: openInFinder)
    }
    
    private func displayBuildResult(_ binaryOutput: BinaryOutput, openInFinder: Bool) {
        switch binaryOutput {
        case .single(let binaryInfo):
            print("New binary was built at \(binaryInfo.path)")
            if openInFinder {
                _ = try? shell.bash("open -R \(binaryInfo.path)")
            }
        case .multiple(let binaries):
            print("Universal binary built:")
            for (arch, binaryInfo) in binaries {
                print("  \(arch.name): \(binaryInfo.path)")
            }
            if openInFinder, let firstBinary = binaries.values.first {
                _ = try? shell.bash("open -R \(firstBinary.path)")
            }
        }
    }
    
    private func getExecutableName(for projectFolder: Folder) throws -> String {
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
    
    private func selectOutputLocation(buildType: BuildType) throws -> BuildOutputLocation {
        let options: [BuildOutputLocation] = [
            .currentDirectory(buildType),
            .desktop,
            .custom("")
        ]
        
        let selection = try picker.requiredSingleSelection(title: "Where would you like to place the built binary?", items: options)
        
        if case .custom = selection {
            return try handleCustomLocationInput()
        }
        
        return selection
    }
    
    private func handleCustomLocationInput() throws -> BuildOutputLocation {
        let parentPath = try picker.getRequiredInput(prompt: "Enter the path to the parent directory where you want to place the binary:")
        
        guard let parentFolder = try? Folder(path: parentPath) else {
            throw NSError(domain: "BuildError", code: 1, userInfo: [NSLocalizedDescriptionKey: "The specified path '\(parentPath)' does not exist or is not accessible."])
        }
        
        let confirmed = picker.getPermission(prompt: "The binary will be placed at: \(parentFolder.path). Continue?")
        guard confirmed else {
            throw NSError(domain: "BuildError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Build cancelled by user."])
        }
        
        return .custom(parentFolder.path)
    }
    
    private func copyBinaryToLocation(binaryOutput: BinaryOutput, outputLocation: BuildOutputLocation, executableName: String) throws -> BinaryOutput {
        switch outputLocation {
        case .currentDirectory:
            return binaryOutput
            
        case .desktop:
            let desktop = try Folder.home.subfolder(named: "Desktop")
            return try copyToDestination(binaryOutput: binaryOutput, destinationPath: desktop.path, executableName: executableName)
            
        case .custom(let parentPath):
            return try copyToDestination(binaryOutput: binaryOutput, destinationPath: parentPath, executableName: executableName)
        }
    }
    
    private func copyToDestination(binaryOutput: BinaryOutput, destinationPath: String, executableName: String) throws -> BinaryOutput {
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
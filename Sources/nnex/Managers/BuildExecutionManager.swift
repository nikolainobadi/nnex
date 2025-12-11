//
//  BuildExecutionManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import NnexKit
import Foundation

struct BuildExecutionManager {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let copyUtility: BinaryCopyUtility
    
    init(shell: any NnexShell, picker: any NnexPicker, fileSystem: any FileSystem) {
        self.shell = shell
        self.picker = picker
        self.fileSystem = fileSystem
        self.copyUtility = .init(shell: shell, fileSystem: fileSystem)
    }
    
    func executeBuild(projectPath: String?, buildType: BuildType, clean: Bool, openInFinder: Bool) throws {
        let projectFolder = try getProjectFolder(at: projectPath)
        let executableName = try getExecutableName(for: projectFolder)
        let outputLocation = try selectOutputLocation(buildType: buildType)
        let config = BuildConfig(projectName: executableName, projectPath: projectFolder.path, buildType: buildType, extraBuildArgs: [], skipClean: !clean, testCommand: nil)
        let builder = ProjectBuilder(shell: shell, config: config)
        let binaryOutput = try builder.build()
        
        let finalPaths = try copyUtility.copyBinaryToLocation(binaryOutput: binaryOutput, outputLocation: outputLocation, executableName: executableName)
        
        displayBuildResult(finalPaths, openInFinder: openInFinder)
    }
}


// MARK: - Private Methods
private extension BuildExecutionManager {
    func getProjectFolder(at path: String?) throws -> any Directory {
        if let path {
            return try fileSystem.directory(at: path)
        }
        
        return fileSystem.currentDirectory
    }
    
    func displayBuildResult(_ binaryOutput: BinaryOutput, openInFinder: Bool) {
        switch binaryOutput {
        case .single(let path):
            print("New binary was built at \(path)")
            if openInFinder {
                try? shell.runAndPrint(bash: "open -R \(path)")
            }
        case .multiple(let binaries):
            print("Universal binary built:")
            for (arch, path) in binaries {
                print("  \(arch.name): \(path)")
            }
            if openInFinder, let firstPath = binaries.values.first {
                try? shell.runAndPrint(bash: "open -R \(firstPath)")
            }
        }
    }
    
    func getExecutableName(for folder: any Directory) throws -> String {
        let names = try ExecutableNameResolver.getExecutableNames(from: folder)
        
        guard names.count > 1 else {
            return names.first!
        }
        
        do {
            return try picker.requiredSingleSelection("Which executable would you like to build?", items: names)
        } catch {
            throw BuildExecutionError.failedToSelectExecutable(reason: error.localizedDescription)
        }
    }
    
    func selectOutputLocation(buildType: BuildType) throws -> BuildOutputLocation {
        let options: [BuildOutputLocation] = [
            .currentDirectory(buildType),
            .desktop,
            .custom("")
        ]
        
        let selection = try picker.requiredSingleSelection("Where would you like to place the built binary?", items: options)
        
        if case .custom = selection {
            return try handleCustomLocationInput()
        }
        
        return selection
    }
    
    func handleCustomLocationInput() throws -> BuildOutputLocation {
        let parentPath = try picker.getRequiredInput(prompt: "Enter the path to the parent directory where you want to place the binary:")
        
        guard let parentFolder = try? fileSystem.directory(at: parentPath) else {
            throw BuildExecutionError.invalidCustomPath(path: parentPath)
        }
        
        let confirmed = picker.getPermission(prompt: "The binary will be placed at: \(parentFolder.path). Continue?")
        guard confirmed else {
            throw BuildExecutionError.buildCancelledByUser
        }
        
        return .custom(parentFolder.path)
    }
}

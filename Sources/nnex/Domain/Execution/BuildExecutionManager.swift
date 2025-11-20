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
    private let picker: any NnexPicker
    private let copyUtility: BinaryCopyUtility
    
    init(shell: any Shell, picker: any NnexPicker) {
        self.shell = shell
        self.picker = picker
        self.copyUtility = BinaryCopyUtility(shell: shell)
    }
    
    func executeBuild(projectPath: String?, buildType: BuildType, clean: Bool, openInFinder: Bool) throws {
        let projectFolder = try Nnex.Brew.getProjectFolder(at: projectPath)
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
    func displayBuildResult(_ binaryOutput: BinaryOutput, openInFinder: Bool) {
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
    
    func getExecutableName(for projectFolder: Folder) throws -> String {
        let resolver = ExecutableNameResolver()
        let names = try resolver.getExecutableNames(from: projectFolder)
        
        guard names.count > 1 else {
            return names.first!
        }
        
        do {
            return try picker.requiredSingleSelection(title: "Which executable would you like to build?", items: names)
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
        
        let selection = try picker.requiredSingleSelection(title: "Where would you like to place the built binary?", items: options)
        
        if case .custom = selection {
            return try handleCustomLocationInput()
        }
        
        return selection
    }
    
    func handleCustomLocationInput() throws -> BuildOutputLocation {
        let parentPath = try picker.getRequiredInput(prompt: "Enter the path to the parent directory where you want to place the binary:")
        
        guard let parentFolder = try? Folder(path: parentPath) else {
            throw BuildExecutionError.invalidCustomPath(path: parentPath)
        }
        
        let confirmed = picker.getPermission(prompt: "The binary will be placed at: \(parentFolder.path). Continue?")
        guard confirmed else {
            throw BuildExecutionError.buildCancelledByUser
        }
        
        return .custom(parentFolder.path)
    }
}

//
//  BuildBinaryController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import NnexKit

struct BuildBinaryController {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let service: any BuildBinaryService
    private let folderBrowser: any DirectoryBrowser
    
    init(
        shell: any NnexShell,
        picker: any NnexPicker,
        fileSystem: any FileSystem,
        service: any BuildBinaryService,
        folderBrowser: any DirectoryBrowser
    ) {
        self.shell = shell
        self.picker = picker
        self.fileSystem = fileSystem
        self.service = service
        self.folderBrowser = folderBrowser
    }
}


// MARK: - Actions
extension BuildBinaryController {
    func buildBinary(path: String?, buildType: BuildType, clean: Bool, openInFinder: Bool) throws {
//        let projectFolder = try fileSystem.getDirectoryAtPathOrCurrent(path: path)
//        let executableName = try getExecutableName(for: projectFolder)
//        let outputLocation = try selectOutputLocation(buildType: buildType)
//        let config = BuildConfig(projectName: executableName, projectPath: projectFolder.path, buildType: buildType, extraBuildArgs: [], skipClean: !clean, testCommand: nil)
//        let builder = ProjectBuilder(shell: shell, config: config)
//        let _ = try builder.build()
        
        // TODO: -
    }
}


// MARK: - Private Methods
private extension BuildBinaryController {
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

protocol BuildBinaryService {
    
}

//
//  BuildBinaryController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
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
    func buildBinary(info: BuildInfo) throws {
        let projectFolder = try getFolder(at: info.path)
        let executableName = try getExecutableName(from: projectFolder)
        let config = try makeBuildConfig(for: projectFolder, info: info, executableName: executableName)
        let binaryOutput = try service.build(config: config)
        let outputLocation = try selectOutputLocation(buildType: info.type)
        let result = try service.moveBinary(binaryOutput, to: outputLocation, executableName: executableName)
        
        displayBuildResult(result, openInFinder: info.openInFinder)
    }
}


// MARK: - Private Methods
private extension BuildBinaryController {
    func getFolder(at path: String?) throws -> any Directory {
        guard let path else {
            return fileSystem.currentDirectory
        }
        
        return try fileSystem.directory(at: path)
    }
    
    func makeBuildConfig(for folder: any Directory, info: BuildInfo, executableName: String) throws -> BuildConfig {
        return .init(projectName: executableName, projectPath: folder.path, buildType: info.type, extraBuildArgs: [], skipClean: !info.clean, testCommand: nil)
    }
    
    func getExecutableName(from folder: any Directory) throws -> String {
        let names = try service.getExecutableNames(from: folder)
        
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
        let options: [BuildOutputLocation] = [.currentDirectory(buildType), .desktop, .custom("")]
        let selection = try picker.requiredSingleSelection("Where would you like to place the built binary?", items: options)
        
        switch selection {
        case .custom:
            return try handleCustomLocationInput()
        default:
            return selection
        }
    }
    
    func handleCustomLocationInput() throws -> BuildOutputLocation {
        let parentFolder = try folderBrowser.browseForDirectory(prompt: "Select the parent directory where you want the binary to be built.")
        
        let confirmed = picker.getPermission(prompt: "The binary will be placed at: \(parentFolder.path). Continue?")
        guard confirmed else {
            throw BuildExecutionError.buildCancelledByUser
        }
        
        return .custom(parentFolder.path)
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
            
            if openInFinder, let firstBinaryPath = binaries.values.first {
                try? shell.runAndPrint(bash: "open -R \(firstBinaryPath)")
            }
        }
    }
}


// MARK: - Dependencies
extension BuildBinaryController {
    struct BuildInfo {
        let path: String?
        let type: BuildType
        let clean: Bool
        let openInFinder: Bool
    }
}

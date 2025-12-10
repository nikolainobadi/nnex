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
        let config = try makeBuildConfig(for: projectFolder, info: info)
        let binaryOutput = try service.build(config: config)
        let outputLocation = try selectOutputLocation(buildType: info.type)
        let result = try service.moveBinary(binaryOutput, to: outputLocation)
        
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
    
    func makeBuildConfig(for folder: any Directory, info: BuildInfo) throws -> BuildConfig {
        let executableName = try getExecutableName(from: folder)
        
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
        case .single(let binaryInfo):
            print("New binary was built at \(binaryInfo.path)")
            if openInFinder {
                try? shell.runAndPrint(bash: "open -R \(binaryInfo.path)")
            }
        case .multiple(let binaries):
            print("Universal binary built:")
            for (arch, binaryInfo) in binaries {
                print("  \(arch.name): \(binaryInfo.path)")
            }
            if openInFinder, let firstBinary = binaries.values.first {
                try? shell.runAndPrint(bash: "open -R \(firstBinary.path)")
            }
        }
    }
}


// MARK: - Dependencies
protocol BuildBinaryService {
    func build(config: BuildConfig) throws -> BinaryOutput
    func getExecutableNames(from directory: any Directory) throws -> [String]
    func moveBinary(_ binary: BinaryOutput, to location: BuildOutputLocation) throws -> BinaryOutput
}

extension BuildBinaryController {
    struct BuildInfo {
        let path: String?
        let type: BuildType
        let clean: Bool
        let openInFinder: Bool
    }
}

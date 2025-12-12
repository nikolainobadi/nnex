//
//  BuildController.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

import NnexKit

struct BuildController {
    private let shell: any NnexShell
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let buildService: any BuildService
    private let folderBrowser: any DirectoryBrowser
    
    init(
        shell: any NnexShell,
        picker: any NnexPicker,
        fileSystem: any FileSystem,
        buildService: any BuildService,
        folderBrowser: any DirectoryBrowser
    ) {
        self.shell = shell
        self.picker = picker
        self.fileSystem = fileSystem
        self.buildService = buildService
        self.folderBrowser = folderBrowser
    }
}


// MARK: - BuildExecutable
extension BuildController {
    func buildExecutable(path: String?, buildType: BuildType, clean: Bool, openInFinder: Bool) throws {
        let projectFolder = try fileSystem.getDirectoryAtPathOrCurrent(path: path)
        let outputLocation = try selectOutputLocation(buildType: buildType)
        let result = try buildExecutable(projectFolder: projectFolder, buildType: buildType, clean: clean, outputLocation: outputLocation, extraBuildArgs: [], testCommand: nil)
        
        displayBuildResult(result, openInFinder: openInFinder)
    }
}


// MARK: - PublishBuilder
extension BuildController {
    func buildExecutable(projectFolder: any Directory, buildType: BuildType, clean: Bool, outputLocation: BuildOutputLocation?, extraBuildArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildResult {
        let outputLocation = try selectOutputLocation(buildType: buildType)
        let config = try makeBuildConfig(for: projectFolder, buildType: buildType, clean: clean, extraArgs: extraBuildArgs, testCommand: testCommand)
        
        return try buildService.buildExecutable(config: config, outputLocation: outputLocation)
    }
}


// MARK: - Private Methods
private extension BuildController {
    func makeBuildConfig(for folder: any Directory, buildType: BuildType, clean: Bool, extraArgs: [String], testCommand: HomebrewFormula.TestCommand?) throws -> BuildConfig {
        let executableName = try getExecutableName(for: folder)
        
        // TODO: - maybe prompt for extra args and test command?
        return .init(projectName: executableName, projectPath: folder.path, buildType: buildType, extraBuildArgs: extraArgs, skipClean: !clean, testCommand: testCommand)
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
        let options: [BuildOutputLocation] = [.currentDirectory(buildType), .desktop, .custom("")]
        let selection = try picker.requiredSingleSelection("Where would you like to place the built binary?", items: options)
        
        if case .custom = selection {
            return try handleCustomLocationInput()
        }
        
        return selection
    }
    
    func handleCustomLocationInput() throws -> BuildOutputLocation {
        let parentFolder = try folderBrowser.browseForDirectory(prompt: "Select the folder where you would like to save the build.")
        
        try picker.requiredPermission(prompt: "The binary will be placed at: \(parentFolder.path). Continue?")
        
        return .custom(parentFolder.path)
    }
    
    func displayBuildResult(_ result: BuildResult, openInFinder: Bool) {
        switch result.binaryOutput {
        case .single(let path):
            print("\(result.executableName.lightGreen) was built at \(path)")
            openFinder(path: openInFinder ? path : nil)
        case .multiple(let binaries):
            print("\(result.executableName.lightGreen) builds:".underline)
            for (arch, path) in binaries {
                print("  \(arch.name): \(path)")
            }
            
            openFinder(path: openInFinder ? binaries.values.first : nil)
        }
    }
    
    func openFinder(path: String?) {
        if let path {
            try? shell.runAndPrint(bash: "open -R \(path)")
        }
    }
}


// MARK: - Dependencies
protocol BuildService {
    func buildExecutable(config: BuildConfig, outputLocation: BuildOutputLocation) throws -> BuildResult
}

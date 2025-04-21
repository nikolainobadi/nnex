//
//  BuildExecutable.swift
//  nnex
//
//  Created by Nikolai Nobadi on 4/21/25.
//

import Files
import NnexKit
import ArgumentParser

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
        
        func run() throws {
            let shell = Nnex.makeShell()
            let context = try Nnex.makeContext()
            let buildType = buildType ?? context.loadDefaultBuildType()
            let projectFolder = try Nnex.Brew.getProjectFolder(at: path)
            let executableName = try getExecutableName(for: projectFolder)
            let config = BuildConfig(projectName: executableName, projectPath: projectFolder.path, buildType: buildType, extraBuildArgs: [], skipClean: true, testCommand: nil)
            let builder = ProjectBuilder(shell: shell, config: config)
            let binaryInfo = try builder.build()
            
            print("New binary was built at \(binaryInfo.path)")
            
            if openInFinder {
                try shell.runAndPrint("open -R \(binaryInfo.path)")
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
}

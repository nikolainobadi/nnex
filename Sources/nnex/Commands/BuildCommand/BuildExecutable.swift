//
//  BuildExecutable.swift
//  nnex
//
//  Created by Nikolai Nobadi on 4/21/25.
//

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
        
        @Flag(inversion: .prefixedNo, help: "Clean the build directory before building. Defaults to true.")
        var clean: Bool = true
        
        func run() throws {
            let shell = Nnex.makeShell()
            let picker = Nnex.makePicker()
            let context = try Nnex.makeContext()
            let buildType = buildType ?? context.loadDefaultBuildType()
            let manager = BuildExecutionManager(shell: shell, picker: picker)

            try manager.executeBuild(projectPath: path, buildType: buildType, clean: clean, openInFinder: openInFinder)
        }
    }
}

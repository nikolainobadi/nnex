//
//  BuildBinary.swift
//  nnex
//
//  Created by Nikolai Nobadi on 4/21/25.
//

import NnexKit
import ArgumentParser

extension Nnex {
    struct BuildBinary: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "build",
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
            let context = try Nnex.makeContext()
            let buildType = buildType ?? context.loadDefaultBuildType()
            
            try Nnex.makeBuildController().buildBinary(info: .init(path: path, type: buildType, clean: clean, openInFinder: openInFinder))
        }
    }
}

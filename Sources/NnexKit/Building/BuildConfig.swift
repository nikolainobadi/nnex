//
//  BuildConfig.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/25/25.
//

/// Represents the configuration for building a project.
public struct BuildConfig: Sendable {
    /// The name of the project to build.
    public let projectName: String
    /// The file path to the project directory.
    public let projectPath: String
    /// The type of build to perform (e.g., universal, arm64, x86_64).
    public let buildType: BuildType
    /// Additional arguments to pass to the build command.
    public let extraBuildArgs: [String]
    /// Indicates whether the project should be cleaned before building.
    public let skipClean: Bool
    public let testCommand: TestCommand?

    /// Initializes a new `BuildConfig` with the specified settings.
    ///
    /// - Parameters:
    ///   - projectName: The name of the project to build.
    ///   - projectPath: The file path to the project directory.
    ///   - buildType: The type of build to perform (e.g., universal, arm64, x86_64).
    ///   - extraBuildArgs: Additional arguments to pass to the build command.
    ///   - shouldClean: Indicates whether the project should be cleaned before building. Defaults to `true`.
    ///   - testCommand: An optional command to run tests after building. Defaults to `nil`, meaning no tests will be run.
    public init(projectName: String, projectPath: String, buildType: BuildType, extraBuildArgs: [String], skipClean: Bool, testCommand: TestCommand?) {
        self.projectName = projectName
        self.projectPath = projectPath.hasSuffix("/") ? projectPath : projectPath + "/"
        self.buildType = buildType
        self.extraBuildArgs = extraBuildArgs
        self.skipClean = skipClean
        self.testCommand = testCommand
    }
}


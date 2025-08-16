//
//  ProjectBuilder.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

/// Responsible for building projects and creating binary files.
public struct ProjectBuilder {
    private let shell: Shell
    private let config: BuildConfig
    private let progressDelegate: BuildProgressDelegate?

    /// Initializes a new instance of ProjectBuilder.
    /// - Parameters:
    ///   - shell: The shell used to execute build commands.
    ///   - config: The configuration containing build settings.
    ///   - progressDelegate: An optional delegate to handle progress updates.
    public init(shell: Shell, config: BuildConfig, progressDelegate: BuildProgressDelegate? = nil) {
        self.shell = shell
        self.config = config
        self.progressDelegate = progressDelegate
    }
}


// MARK: - Build
public extension ProjectBuilder {
    /// Builds a project based on the configuration.
    /// - Returns: A BinaryInfo object containing the binary path and SHA256 hash.
    /// - Throws: An error if the build process fails.
    func build() throws -> BinaryInfo {
        if !config.skipClean {
            try cleanProject()
        }

        for arch in config.buildType.archs {
            try build(for: arch)
        }

        let binaryPath: String
        if config.buildType == .universal {
            binaryPath = try buildUniversalBinary()
        } else {
            binaryPath = "\(config.projectPath).build/\(config.buildType.archs.first!.name)-apple-macosx/release/\(config.projectName)"
        }

        let sha256 = try getSha256(binaryPath: binaryPath)
        try runTests() // Run tests after building
        return .init(path: binaryPath, sha256: sha256)
    }
}


// MARK: - Private Methods
private extension ProjectBuilder {
    /// Logs a progress message using the delegate or falls back to printing.
    /// - Parameter message: The message to log.
    func log(_ message: String) {
        if let progressDelegate = progressDelegate {
            progressDelegate.didUpdateProgress(message)
        } else {
            print(message)
        }
    }

    /// Cleans the project before building.
    /// - Throws: An error if the clean process fails.
    func cleanProject() throws {
        log("🧹 Cleaning the project...")
        let cleanCommand = "swift package clean --package-path \(config.projectPath)"
        try shell.runAndPrint(cleanCommand)
        log("✅ Project cleaned.")
    }

    /// Runs tests based on the configured test command.
    /// - Throws: An error if the test process fails.
    func runTests() throws {
        if let testCommandEnum = config.testCommand {
            let testCommand: String
            switch testCommandEnum {
            case .defaultCommand:
                testCommand = "swift test --package-path \(config.projectPath)"
            case .custom(let command):
                testCommand = command
            }
            
            log("🧪 Running tests: \(testCommand)")
            try shell.runAndPrint(testCommand)
            log("✅ Tests completed successfully.")
        }
    }

    /// Builds the project for the specified architecture.
    /// - Parameter arch: The target architecture for the build.
    /// - Throws: An error if the build process fails.
    func build(for arch: ReleaseArchitecture) throws {
        log("🔨 Building for \(arch.name)...")
        let buildCommand = """
        swift build -c release --arch \(arch.name) -Xswiftc -Osize -Xswiftc -wmo -Xlinker -dead_strip_dylibs --package-path \(config.projectPath) \(config.extraBuildArgs.joined(separator: " "))
        """
        try shell.runAndPrint(buildCommand)
    }

    /// Retrieves the SHA256 hash of a binary file.
    /// - Parameter binaryPath: The file path to the binary.
    /// - Returns: The SHA256 hash as a string.
    /// - Throws: An error if the hash calculation fails.
    func getSha256(binaryPath: String) throws -> String {
        guard let sha256 = try? shell.run("shasum -a 256 \(binaryPath)").components(separatedBy: " ").first else {
            throw NnexError.missingSha256
        }
        return sha256
    }

    /// Builds a universal binary by combining architectures.
    /// - Returns: The file path of the created universal binary.
    /// - Throws: An error if the binary creation fails.
    func buildUniversalBinary() throws -> String {
        let buildPath = "\(config.projectPath).build/universal"
        let universalBinaryPath = "\(buildPath)/\(config.projectName)"

        log("📂 Creating universal binary folder at: \(buildPath)")
        try shell.runAndPrint("mkdir -p \(buildPath)")

        log("🔗 Combining architectures into universal binary...")
        let lipoCommand = """
        lipo -create -output \(universalBinaryPath) \
        \(config.projectPath).build/arm64-apple-macosx/release/\(config.projectName) \
        \(config.projectPath).build/x86_64-apple-macosx/release/\(config.projectName)
        """
        try shell.runAndPrint(lipoCommand)

        log("🗑 Stripping unneeded symbols...")
        try shell.runAndPrint("strip -u -r \(universalBinaryPath)")

        log("✅ Universal binary created at: \(universalBinaryPath)")
        return universalBinaryPath
    }
}

// MARK: - Dependencies
public protocol BuildProgressDelegate: AnyObject {
    func didUpdateProgress(_ message: String)
}


// MARK: - Extension Dependencies
fileprivate extension BuildType {
    /// Returns the list of architectures associated with the build type.
    var archs: [ReleaseArchitecture] {
        switch self {
        case .arm64:
            return [.arm]
        case .x86_64:
            return [.intel]
        case .universal:
            return [.arm, .intel]
        }
    }
}

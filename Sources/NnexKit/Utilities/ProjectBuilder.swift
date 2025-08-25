import NnShellKit

public struct ProjectBuilder {
    private let shell: any Shell
    private let config: BuildConfig
    private let progressDelegate: BuildProgressDelegate?

    public init(shell: any Shell, config: BuildConfig, progressDelegate: BuildProgressDelegate? = nil) {
        self.shell = shell
        self.config = config
        self.progressDelegate = progressDelegate
    }
}


// MARK: - Build
public extension ProjectBuilder {
    func build() throws -> BinaryOutput {
        if !config.skipClean {
            try cleanProject()
        }

        for arch in config.buildType.archs {
            try build(for: arch)
        }

        switch config.buildType {
        case .arm64, .x86_64:
            let arch = config.buildType.archs.first!
            let path = binaryPath(for: arch)
            let sha256 = try getSha256(binaryPath: path)
            
            try runTests()
            
            return .single(.init(path: path, sha256: sha256))

        case .universal:
            var results: [ReleaseArchitecture: BinaryInfo] = [:]
            for arch in config.buildType.archs {
                let path = binaryPath(for: arch)
                let sha256 = try getSha256(binaryPath: path)
                results[arch] = .init(path: path, sha256: sha256)
            }
            
            try runTests()
            
            return .multiple(results)
        }
    }
}


// MARK: - Private Methods
private extension ProjectBuilder {
    func log(_ message: String) {
        if let progressDelegate = progressDelegate {
            progressDelegate.didUpdateProgress(message)
        } else {
            print(message)
        }
    }

    func cleanProject() throws {
        log("🧹 Cleaning the project...")
        let output = try shell.bash("swift package clean --package-path \(config.projectPath)")
        if !output.isEmpty { print(output) }
        log("✅ Project cleaned.")
    }

    func runTests() throws {
        if let testCommandEnum = config.testCommand {
            var testCommand: String
            switch testCommandEnum {
            case .defaultCommand:
                testCommand = "swift test --package-path \(config.projectPath)"
            case .custom(let command):
                testCommand = command
                
                let additions = ["-quiet", "-allowProvisioningUpdates"]
                
                for addition in additions {
                    if !testCommand.contains(addition) {
                        testCommand.append(" \(addition)")
                    }
                }
            }
            log("🧪 Running tests: \(testCommand)")
            let output = try shell.bash(testCommand)
            if !output.isEmpty { print(output) }
            log("✅ Tests completed successfully.")
        }
    }

    func build(for arch: ReleaseArchitecture) throws {
        log("🔨 Building for \(arch.name)...")
        let extra = config.extraBuildArgs.joined(separator: " ")
        let cmd = "swift build -c release --arch \(arch.name) -Xswiftc -Osize -Xswiftc -wmo -Xlinker -dead_strip_dylibs --package-path \(config.projectPath) \(extra)"
        let output = try shell.bash(cmd)
        if !output.isEmpty { print(output) }
    }

    func binaryPath(for arch: ReleaseArchitecture) -> String {
        "\(config.projectPath).build/\(arch.name)-apple-macosx/release/\(config.projectName)"
    }

    func getSha256(binaryPath: String) throws -> String {
        guard
            let raw = try? shell.bash("shasum -a 256 \(binaryPath)"),
            let sha = raw.components(separatedBy: " ").first,
            !sha.isEmpty
        else { throw NnexError.missingSha256 }
        return sha
    }
}

public enum BinaryOutput {
    case single(BinaryInfo)
    case multiple([ReleaseArchitecture: BinaryInfo])
}

public protocol BuildProgressDelegate: AnyObject {
    func didUpdateProgress(_ message: String)
}

private extension BuildType {
    var archs: [ReleaseArchitecture] {
        switch self {
        case .arm64: return [.arm]
        case .x86_64: return [.intel]
        case .universal: return [.arm, .intel]
        }
    }
}

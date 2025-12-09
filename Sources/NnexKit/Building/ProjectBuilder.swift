//
//  ProjectBuilder.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import Foundation
import NnShellKit

public struct ProjectBuilder {
    private let shell: any NnexShell
    private let config: BuildConfig
    private let progressDelegate: (any BuildProgressDelegate)?

    public init(shell: any NnexShell, config: BuildConfig, progressDelegate: (any BuildProgressDelegate)? = nil) {
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
            
            try runTests()
            
            return .single(.init(path: path))

        case .universal:
            var results: [ReleaseArchitecture: BinaryInfo] = [:]
            for arch in config.buildType.archs {
                let path = binaryPath(for: arch)
                results[arch] = .init(path: path)
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
        try shell.runAndPrint(bash: "swift package clean --package-path \(config.projectPath)")
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
            
            do {
                try shell.runAndPrint(bash: testCommand)
                log("✅ Tests completed successfully.")
            } catch let shellError as ShellError {
                // Extract test output from the shell error
                if case .failed(_, _, let output) = shellError {
                    if !output.isEmpty {
                        print("\n❌ Test failures:")
                        print(output)
                    } else {
                        print("\n❌ Tests failed (no output captured)")
                    }
                    throw TestFailureError(command: testCommand, output: output)
                } else {
                    throw shellError
                }
            } catch {
                print("\n❌ Tests failed with unexpected error: \(error)")
                throw TestFailureError(command: testCommand, output: error.localizedDescription)
            }
        }
    }

    func build(for arch: ReleaseArchitecture) throws {
        log("🔨 Building for \(arch.name)...")
        let extra = config.extraBuildArgs.joined(separator: " ")
        let cmd = "swift build -c release --arch \(arch.name) -Xswiftc -Osize -Xswiftc -wmo -Xswiftc -gnone -Xswiftc -cross-module-optimization -Xlinker -dead_strip_dylibs --package-path \(config.projectPath) \(extra)"
        
        try shell.runAndPrint(bash: cmd)
        try stripBinary(for: arch)
    }

    func binaryPath(for arch: ReleaseArchitecture) -> String {
        "\(config.projectPath).build/\(arch.name)-apple-macosx/release/\(config.projectName)"
    }
    
    func stripBinary(for arch: ReleaseArchitecture) throws {
        log("✂️ Stripping binary for \(arch.name)...")
        let binaryPath = binaryPath(for: arch)
        let stripCmd = "strip -x \"\(binaryPath)\""
        
        try shell.runAndPrint(bash: stripCmd)
        log("✅ Binary stripped for \(arch.name).")
    }
}


// MARK: - Dependencies
public enum BinaryOutput {
    case single(BinaryInfo)
    case multiple([ReleaseArchitecture: BinaryInfo])
}

public protocol BuildProgressDelegate: AnyObject {
    func didUpdateProgress(_ message: String)
}

public struct TestFailureError: Error, LocalizedError {
    let command: String
    let output: String
    
    public var errorDescription: String? {
        if output.isEmpty {
            return "Tests failed when running: \(command)"
        } else {
            return "Tests failed when running: \(command)\n\nTest output:\n\(output)"
        }
    }
}


// MARK: - Extension Dependencies
private extension BuildType {
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

//
//  DefaultProjectBuilder.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import SwiftShell

struct DefaultProjectBuilder: ProjectBuilder {
    func buildProject(name: String, path: String) throws -> UniversalBinaryPath {
        let projectPath = path.hasSuffix("/") ? path : path + "/"
        
        try build(for: .arm, projectPath: projectPath)
        try build(for: .intel, projectPath: projectPath)
        
        return try buildUniversalBinary(projectName: name, projectPath: projectPath)
    }
}

// MARK: - Private Methods
private extension DefaultProjectBuilder {
    func build(for arch: ReleaseArchitecture, projectPath: String) throws {
        print("🔨 Building for \(arch.name)...")
        let buildCommand = """
        swift build -c release --arch \(arch.name) -Xswiftc -Osize -Xswiftc -wmo -Xlinker -dead_strip_dylibs --package-path \(projectPath)
        """
        try SwiftShell.runAndPrint(bash: buildCommand)
    }

    func buildUniversalBinary(projectName: String, projectPath: String) throws -> UniversalBinaryPath {
        let buildPath = "\(projectPath).build/universal"
        let universalBinaryPath = "\(buildPath)/\(projectName)"

        // Check if the universal folder already exists
        if SwiftShell.run(bash: "test -d \(buildPath)").exitcode == 0 {
            print("⚠️ Universal binary folder already exists at: \(buildPath)")
            print("🗑 Removing existing universal folder...")
            try SwiftShell.runAndPrint(bash: "rm -rf \(buildPath)")
        }

        print("📂 Creating universal binary folder at: \(buildPath)")
        try SwiftShell.runAndPrint(bash: "mkdir -p \(buildPath)")

        print("🔗 Combining architectures into universal binary...")
        let lipoCommand = """
        lipo -create -output \(universalBinaryPath) \
        \(projectPath).build/arm64-apple-macosx/release/\(projectName) \
        \(projectPath).build/x86_64-apple-macosx/release/\(projectName)
        """
        try SwiftShell.runAndPrint(bash: lipoCommand)

        print("🗑 Stripping unneeded symbols...")
        try SwiftShell.runAndPrint(bash: "strip -u -r \(universalBinaryPath)")

        print("✅ Universal binary created at: \(universalBinaryPath)")
        
        return universalBinaryPath
    }
}

// MARK: - Dependencies
enum ReleaseArchitecture {
    case arm, intel
    
    var name: String {
        switch self {
        case .arm:
            return "arm64"
        case .intel:
            return "x86_64"
        }
    }
}


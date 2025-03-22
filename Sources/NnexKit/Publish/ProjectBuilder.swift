//
//  ProjectBuilder.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

public struct ProjectBuilder {
    private let shell: Shell
    
    public init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - Build
public extension ProjectBuilder {
    func buildProject(name: String, path: String, buildType: BuildType) throws -> BinaryInfo {
        let projectPath = path.hasSuffix("/") ? path : path + "/"
        
        for arch in buildType.archs {
            try build(for: arch, projectPath: projectPath)
        }
        
        let binaryPath: String
        if buildType == .universal {
            binaryPath = try buildUniversalBinary(projectName: name, projectPath: projectPath)
        } else {
            binaryPath = "\(projectPath).build/\(buildType.archs.first!.name)-apple-macosx/release/\(name)"
        }
        
        let sha256 = try getSha256(binaryPath: binaryPath)
        
        return .init(path: binaryPath, sha256: sha256)
    }
}


// MARK: - Private Methods
private extension ProjectBuilder {
    func build(for arch: ReleaseArchitecture, projectPath: String) throws {
        print("🔨 Building for \(arch.name)...")
        let buildCommand = """
        swift build -c release --arch \(arch.name) -Xswiftc -Osize -Xswiftc -wmo -Xlinker -dead_strip_dylibs --package-path \(projectPath)
        """
        
        try shell.runAndPrint(buildCommand)
    }
    
    func getSha256(binaryPath: String) throws -> String {
        guard let sha256 = try? shell.run("shasum -a 256 \(binaryPath)").components(separatedBy: " ").first else {
            throw NnexError.missingSha256
        }
        
        return sha256
    }

    func buildUniversalBinary(projectName: String, projectPath: String) throws -> String {
        let buildPath = "\(projectPath).build/universal"
        let universalBinaryPath = "\(buildPath)/\(projectName)"
        
        print("📂 Creating universal binary folder at: \(buildPath)")
        try shell.runAndPrint("mkdir -p \(buildPath)")

        print("🔗 Combining architectures into universal binary...")
        let lipoCommand = """
        lipo -create -output \(universalBinaryPath) \
        \(projectPath).build/arm64-apple-macosx/release/\(projectName) \
        \(projectPath).build/x86_64-apple-macosx/release/\(projectName)
        """
        try shell.runAndPrint(lipoCommand)

        print("🗑 Stripping unneeded symbols...")
        try shell.runAndPrint("strip -u -r \(universalBinaryPath)")

        print("✅ Universal binary created at: \(universalBinaryPath)")
        
        return universalBinaryPath
    }
}


// MARK: - Extension Dependencies
fileprivate extension BuildType {
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

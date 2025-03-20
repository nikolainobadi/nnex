//
//  ProjectBuilder.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files

struct ProjectBuilder {
    private let shell: Shell
    
    init(shell: Shell) {
        self.shell = shell
    }
}


// MARK: - Build
extension ProjectBuilder {
    func buildProject(name: String, path: String) throws -> BinaryInfo {
        let projectPath = path.hasSuffix("/") ? path : path + "/"
        
        try build(for: .arm, projectPath: projectPath)
        try build(for: .intel, projectPath: projectPath)
        
        let binaryPath = try buildUniversalBinary(projectName: name, projectPath: projectPath)
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

        // TODO: - this may not be needed
        // deleting ensures a 'clean' folder, but may be unnecessary
        if let universalFolder = try? Folder(path: buildPath) {
            print("⚠️ Universal binary folder already exists at: \(buildPath)")
            print("🗑 Removing existing universal folder...")
            
            try universalFolder.delete()
        }

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

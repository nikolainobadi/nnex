//
//  BuildManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

struct BuildManager {
    private let shell: any NnexShell
    private let fileSystem: any FileSystem
    
    init(shell: any NnexShell, fileSystem: any FileSystem) {
        self.shell = shell
        self.fileSystem = fileSystem
    }
}


// MARK: - BuildExecutable
extension BuildManager {
    func buildExecutable(config: BuildConfig, outputLocation: BuildOutputLocation) throws -> BuildResult {
        let result = try ProjectBuilder(shell: shell, config: config).build()
        
        switch outputLocation {
        case .currentDirectory:
            return result
        case .desktop:
            let desktop = try fileSystem.desktopDirectory()
            
            return try moveToDestination(buildResult: result, destinationPath: desktop.path)
        case .custom(let parentPath):
            return try moveToDestination(buildResult: result, destinationPath: parentPath)
        }
    }
}


// MARK: - Private Methods
private extension BuildManager {
    func moveToDestination(buildResult: BuildResult, destinationPath: String) throws -> BuildResult {
        let executableName = buildResult.executableName
        
        switch buildResult.binaryOutput {
        case .single(let path):
            let finalPath = destinationPath + "/" + executableName
            try shell.runAndPrint(bash: "cp \"\(path)\" \"\(finalPath)\"")
            return .init(executableName: executableName, binaryOutput: .single(finalPath))
        case .multiple(let binaries):
            var results: [ReleaseArchitecture: String] = [:]
            
            for (arch, path) in binaries {
                let finalPath = destinationPath + "/" + executableName + "-\(arch.name)"
                try shell.runAndPrint(bash: "cp \"\(path)\" \"\(finalPath)\"")
                results[arch] = finalPath
            }
            
            return .init(executableName: executableName, binaryOutput: .multiple(results))
        }
    }
}

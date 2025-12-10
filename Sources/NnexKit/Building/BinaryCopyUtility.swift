//
//  BinaryCopyUtility.swift
//  NnexKit
//
//  Created by Nikolai Nobadi on 8/26/25.
//

public struct BinaryCopyUtility {
    private let shell: any NnexShell
    private let fileSystem: any FileSystem

    public init(shell: any NnexShell, fileSystem: any FileSystem) {
        self.shell = shell
        self.fileSystem = fileSystem
    }
}


// MARK: - Actions
public extension BinaryCopyUtility {
    @discardableResult
    func copyBinaryToLocation(binaryOutput: BinaryOutput, outputLocation: BuildOutputLocation, executableName: String) throws -> BinaryOutput {
        switch outputLocation {
        case .currentDirectory:
            return binaryOutput

        case .desktop:
            let desktop = try fileSystem.desktopDirectory()
            return try copyToDestination(binaryOutput: binaryOutput, destinationPath: desktop.path, executableName: executableName)

        case .custom(let parentPath):
            return try copyToDestination(binaryOutput: binaryOutput, destinationPath: parentPath, executableName: executableName)
        }
    }
}


// MARK: - Private Methods
private extension BinaryCopyUtility {
    func copyToDestination(binaryOutput: BinaryOutput, destinationPath: String, executableName: String) throws -> BinaryOutput {
        switch binaryOutput {
        case .single(let binaryInfo):
            let finalPath = destinationPath + "/" + executableName
            try shell.runAndPrint(bash: "cp \"\(binaryInfo.path)\" \"\(finalPath)\"")
            return .single(.init(path: finalPath))
            
        case .multiple(let binaries):
            var results: [ReleaseArchitecture: BinaryInfo] = [:]
            for (arch, binaryInfo) in binaries {
                let finalPath = destinationPath + "/" + executableName + "-\(arch.name)"
                try shell.runAndPrint(bash: "cp \"\(binaryInfo.path)\" \"\(finalPath)\"")
                results[arch] = .init(path: finalPath)
            }
            return .multiple(results)
        }
    }
}

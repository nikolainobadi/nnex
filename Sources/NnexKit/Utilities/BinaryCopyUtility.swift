//
//  BinaryCopyUtility.swift
//  NnexKit
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Files
import NnShellKit

public struct BinaryCopyUtility {
    private let shell: any Shell
    
    public init(shell: any Shell) {
        self.shell = shell
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
            let desktop = try Folder.home.subfolder(named: "Desktop")
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
            _ = try shell.bash("cp \"\(binaryInfo.path)\" \"\(finalPath)\"")
            return .single(.init(path: finalPath))
            
        case .multiple(let binaries):
            var results: [ReleaseArchitecture: BinaryInfo] = [:]
            for (arch, binaryInfo) in binaries {
                let finalPath = destinationPath + "/" + executableName + "-\(arch.name)"
                _ = try shell.bash("cp \"\(binaryInfo.path)\" \"\(finalPath)\"")
                results[arch] = .init(path: finalPath)
            }
            return .multiple(results)
        }
    }
}

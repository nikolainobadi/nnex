//
//  BuildBinaryManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

public struct BuildBinaryManager {
    private let shell: any NnexShell
    private let fileSystem: any FileSystem
    
    public init(shell: any NnexShell, fileSystem: any FileSystem) {
        self.shell = shell
        self.fileSystem = fileSystem
    }
}


// MARK: - BuildBinaryService
extension BuildBinaryManager: BuildBinaryService {
    public func build(config: BuildConfig) throws -> BinaryOutput {
        return try ProjectBuilder(shell: shell, config: config).build()
    }
    
    public func getExecutableNames(from directory: any Directory) throws -> [String] {
        return try ExecutableNameResolver.getExecutableNames(from: directory)
    }
    
    public func moveBinary(_ binary: BinaryOutput, to location: BuildOutputLocation, executableName: String) throws -> BinaryOutput {
        return try BinaryCopyUtility(shell: shell, fileSystem: fileSystem).copyBinaryToLocation(binaryOutput: binary, outputLocation: location, executableName: executableName)
    }
}

public protocol BuildBinaryService {
    func build(config: BuildConfig) throws -> BinaryOutput
    func getExecutableNames(from directory: any Directory) throws -> [String]
    func moveBinary(_ binary: BinaryOutput, to location: BuildOutputLocation, executableName: String) throws -> BinaryOutput
}

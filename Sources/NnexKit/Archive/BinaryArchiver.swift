//
//  BinaryArchiver.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Foundation

public struct BinaryArchiver {
    private let shell: any NnexShell
    
    public init(shell: any NnexShell) {
        self.shell = shell
    }
}


// MARK: - Actions
public extension BinaryArchiver {
    func createArchives(from binaryPaths: [String]) throws -> [ArchivedBinary] {
        var archivedBinaries: [ArchivedBinary] = []
        
        for binaryPath in binaryPaths {
            let archived = try createArchive(from: binaryPath)
            archivedBinaries.append(archived)
        }
        
        return archivedBinaries
    }
    
    func cleanup(_ archivedBinaries: [ArchivedBinary]) throws {
        for archived in archivedBinaries {
            let url = URL(fileURLWithPath: archived.archivePath)
            let fileName = url.lastPathComponent
            
            if fileName.hasSuffix(".tar.gz") {
                let removeCmd = "rm -f \"\(archived.archivePath)\""
                _ = try shell.bash(removeCmd)
            }
        }
    }
}


// MARK: - Private Methods
private extension BinaryArchiver {
    func createArchive(from binaryPath: String) throws -> ArchivedBinary {
        let url = URL(fileURLWithPath: binaryPath)
        let fileName = url.lastPathComponent
        let directory = url.deletingLastPathComponent().path
        
        let archiveName = determineArchiveName(for: binaryPath, fileName: fileName)
        let archivePath = "\(directory)/\(archiveName)"
        
        let tarCmd = "cd \"\(directory)\" && tar -czf \"\(archiveName)\" \"\(fileName)\""
        _ = try shell.bash(tarCmd)
        
        let sha256 = try calculateSHA256(for: archivePath)
        
        return .init(originalPath: binaryPath, archivePath: archivePath, sha256: sha256)
    }
    
    func determineArchiveName(for binaryPath: String, fileName: String) -> String {
        let archSuffix: String
        
        if binaryPath.contains("arm64-apple-macosx") {
            archSuffix = "-arm64"
        } else if binaryPath.contains("x86_64-apple-macosx") {
            archSuffix = "-x86_64"
        } else {
            return "\(fileName).tar.gz"
        }
        
        return fileName + archSuffix + ".tar.gz"
    }
    
    func calculateSHA256(for filePath: String) throws -> String {
        guard
            let raw = try? shell.bash("shasum -a 256 \"\(filePath)\""),
            let sha = raw.components(separatedBy: " ").first,
            !sha.isEmpty
        else {
            throw NnexError.missingSha256
        }
        
        return sha
    }
}

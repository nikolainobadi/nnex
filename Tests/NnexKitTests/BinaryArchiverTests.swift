//
//  BinaryArchiverTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Foundation
import Testing
import NnShellKit
@testable import NnexKit

struct BinaryArchiverTests {
    private let testSha256 = "abc123def456789"
    private let armBinaryPath = "/path/to/.build/arm64-apple-macosx/release/nnex"
    private let intelBinaryPath = "/path/to/.build/x86_64-apple-macosx/release/nnex"
    private let genericBinaryPath = "/path/to/binary/nnex"
}


// MARK: - Single Binary Tests
extension BinaryArchiverTests {
    @Test("Creates archive for ARM64 binary with architecture-specific naming")
    func createsArmArchiveWithCorrectNaming() throws {
        let (sut, shell) = makeSUT(runResults: ["", testSha256])
        
        let result = try sut.createArchives(from: [armBinaryPath])
        
        #expect(result.count == 1)
        let archived = result[0]
        #expect(archived.originalPath == armBinaryPath)
        #expect(archived.archivePath == "/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz")
        #expect(archived.sha256 == testSha256)
        
        #expect(shell.executedCommands.count == 2)
        #expect(shell.executedCommands[0] == "cd \"/path/to/.build/arm64-apple-macosx/release\" && tar -czf \"nnex-arm64.tar.gz\" \"nnex\"")
        #expect(shell.executedCommands[1] == "shasum -a 256 \"/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz\"")
    }
    
    @Test("Creates archive for x86_64 binary with architecture-specific naming")
    func createsIntelArchiveWithCorrectNaming() throws {
        let (sut, shell) = makeSUT(runResults: ["", testSha256])
        
        let result = try sut.createArchives(from: [intelBinaryPath])
        
        #expect(result.count == 1)
        let archived = result[0]
        #expect(archived.originalPath == intelBinaryPath)
        #expect(archived.archivePath == "/path/to/.build/x86_64-apple-macosx/release/nnex-x86_64.tar.gz")
        #expect(archived.sha256 == testSha256)
        
        #expect(shell.executedCommands.count == 2)
        #expect(shell.executedCommands[0] == "cd \"/path/to/.build/x86_64-apple-macosx/release\" && tar -czf \"nnex-x86_64.tar.gz\" \"nnex\"")
        #expect(shell.executedCommands[1] == "shasum -a 256 \"/path/to/.build/x86_64-apple-macosx/release/nnex-x86_64.tar.gz\"")
    }
    
    @Test("Creates generic archive for non-architecture-specific binary path")
    func createsGenericArchiveForNonArchPath() throws {
        let (sut, shell) = makeSUT(runResults: ["", testSha256])
        
        let result = try sut.createArchives(from: [genericBinaryPath])
        
        #expect(result.count == 1)
        let archived = result[0]
        #expect(archived.originalPath == genericBinaryPath)
        #expect(archived.archivePath == "/path/to/binary/nnex.tar.gz")
        #expect(archived.sha256 == testSha256)
        
        #expect(shell.executedCommands.count == 2)
        #expect(shell.executedCommands[0] == "cd \"/path/to/binary\" && tar -czf \"nnex.tar.gz\" \"nnex\"")
        #expect(shell.executedCommands[1] == "shasum -a 256 \"/path/to/binary/nnex.tar.gz\"")
    }
}


// MARK: - Multiple Binary Tests
extension BinaryArchiverTests {
    @Test("Creates archives for both ARM and Intel binaries")
    func createsBothArchitectureArchives() throws {
        let armSha256 = "arm64sha256hash"
        let intelSha256 = "x86_64sha256hash"
        let (sut, shell) = makeSUT(runResults: ["", armSha256, "", intelSha256])
        
        let result = try sut.createArchives(from: [armBinaryPath, intelBinaryPath])
        
        #expect(result.count == 2)
        
        let armArchived = result[0]
        #expect(armArchived.originalPath == armBinaryPath)
        #expect(armArchived.archivePath == "/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz")
        #expect(armArchived.sha256 == armSha256)
        
        let intelArchived = result[1]
        #expect(intelArchived.originalPath == intelBinaryPath)
        #expect(intelArchived.archivePath == "/path/to/.build/x86_64-apple-macosx/release/nnex-x86_64.tar.gz")
        #expect(intelArchived.sha256 == intelSha256)
        
        #expect(shell.executedCommands.count == 4)
        #expect(shell.executedCommands[0] == "cd \"/path/to/.build/arm64-apple-macosx/release\" && tar -czf \"nnex-arm64.tar.gz\" \"nnex\"")
        #expect(shell.executedCommands[1] == "shasum -a 256 \"/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz\"")
        #expect(shell.executedCommands[2] == "cd \"/path/to/.build/x86_64-apple-macosx/release\" && tar -czf \"nnex-x86_64.tar.gz\" \"nnex\"")
        #expect(shell.executedCommands[3] == "shasum -a 256 \"/path/to/.build/x86_64-apple-macosx/release/nnex-x86_64.tar.gz\"")
    }
    
    @Test("Creates archives for mixed architecture and generic binaries")
    func createsMixedArchitectureArchives() throws {
        let armSha256 = "arm64sha256hash"
        let genericSha256 = "genericsha256hash"
        let (sut, _) = makeSUT(runResults: ["", armSha256, "", genericSha256])
        
        let result = try sut.createArchives(from: [armBinaryPath, genericBinaryPath])
        
        #expect(result.count == 2)
        
        let armArchived = result[0]
        #expect(armArchived.originalPath == armBinaryPath)
        #expect(armArchived.archivePath == "/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz")
        #expect(armArchived.sha256 == armSha256)
        
        let genericArchived = result[1]
        #expect(genericArchived.originalPath == genericBinaryPath)
        #expect(genericArchived.archivePath == "/path/to/binary/nnex.tar.gz")
        #expect(genericArchived.sha256 == genericSha256)
    }
    
    @Test("Handles empty binary paths array")
    func handlesEmptyBinaryPaths() throws {
        let (sut, shell) = makeSUT()
        
        let result = try sut.createArchives(from: [])
        
        #expect(result.isEmpty)
        #expect(shell.executedCommands.isEmpty)
    }
}


// MARK: - Archive Cleanup Tests
extension BinaryArchiverTests {
    @Test("Successfully cleans up single archive file")
    func cleanupSingleArchive() throws {
        let archived = ArchivedBinary(
            originalPath: armBinaryPath,
            archivePath: "/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz",
            sha256: testSha256
        )
        let (sut, shell) = makeSUT(runResults: [""])
        
        try sut.cleanup([archived])
        
        #expect(shell.executedCommands.count == 1)
        #expect(shell.executedCommands[0] == "rm -f \"/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz\"")
    }
    
    @Test("Successfully cleans up multiple archive files")
    func cleanupMultipleArchives() throws {
        let armArchived = ArchivedBinary(
            originalPath: armBinaryPath,
            archivePath: "/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz",
            sha256: "armhash"
        )
        let intelArchived = ArchivedBinary(
            originalPath: intelBinaryPath,
            archivePath: "/path/to/.build/x86_64-apple-macosx/release/nnex-x86_64.tar.gz",
            sha256: "intelhash"
        )
        let (sut, shell) = makeSUT(runResults: ["", ""])
        
        try sut.cleanup([armArchived, intelArchived])
        
        #expect(shell.executedCommands.count == 2)
        #expect(shell.executedCommands[0] == "rm -f \"/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz\"")
        #expect(shell.executedCommands[1] == "rm -f \"/path/to/.build/x86_64-apple-macosx/release/nnex-x86_64.tar.gz\"")
    }
    
    @Test("Skips cleanup for non-tar.gz files")
    func skipsNonTarGzFiles() throws {
        let nonTarArchived = ArchivedBinary(
            originalPath: "/path/to/binary",
            archivePath: "/path/to/binary.zip",
            sha256: testSha256
        )
        let (sut, shell) = makeSUT()
        
        try sut.cleanup([nonTarArchived])
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Handles empty archived binaries array for cleanup")
    func handlesEmptyArchivedBinariesForCleanup() throws {
        let (sut, shell) = makeSUT()
        
        try sut.cleanup([])
        
        #expect(shell.executedCommands.isEmpty)
    }
}


// MARK: - Error Handling Tests
extension BinaryArchiverTests {
    @Test("Throws error when tar command fails")
    func throwsErrorWhenTarFails() throws {
        let (sut, _) = makeSUT(throwError: true)
        
        #expect(throws: (any Error).self) {
            try sut.createArchives(from: [armBinaryPath])
        }
    }
    
    @Test("Throws error when SHA256 calculation fails")
    func throwsErrorWhenSha256Fails() throws {
        let (sut, _) = makeSUT(runResults: ["", ""]) // tar succeeds, shasum returns empty
        
        #expect(throws: (any Error).self) {
            try sut.createArchives(from: [armBinaryPath])
        }
    }
    
    @Test("Throws error when SHA256 output is malformed")
    func throwsErrorWhenSha256OutputMalformed() throws {
        let (sut, _) = makeSUT(runResults: ["", " "]) // tar succeeds, shasum returns just space (empty first component)
        
        #expect(throws: (any Error).self) {
            try sut.createArchives(from: [armBinaryPath])
        }
    }
    
    @Test("Throws error when cleanup fails")
    func throwsErrorWhenCleanupFails() throws {
        let archived = ArchivedBinary(
            originalPath: armBinaryPath,
            archivePath: "/path/to/.build/arm64-apple-macosx/release/nnex-arm64.tar.gz",
            sha256: testSha256
        )
        let (sut, _) = makeSUT(throwError: true)
        
        #expect(throws: (any Error).self) {
            try sut.cleanup([archived])
        }
    }
}


// MARK: - Archive Name Generation Tests
extension BinaryArchiverTests {
    @Test("Correctly determines ARM64 archive name from various ARM64 paths")
    func determinesArm64ArchiveName() throws {
        let paths = [
            "/project/.build/arm64-apple-macosx/release/tool",
            "/different/path/.build/arm64-apple-macosx/debug/tool",
            "/home/user/project/.build/arm64-apple-macosx/release/mytool"
        ]
        
        for path in paths {
            let (sut, _) = makeSUT(runResults: ["", testSha256])
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            
            let result = try sut.createArchives(from: [path])
            
            #expect(result.count == 1)
            #expect(result[0].archivePath.contains("\(fileName)-arm64.tar.gz"))
        }
    }
    
    @Test("Correctly determines x86_64 archive name from various Intel paths")
    func determinesIntelArchiveName() throws {
        let paths = [
            "/project/.build/x86_64-apple-macosx/release/tool",
            "/different/path/.build/x86_64-apple-macosx/debug/tool",
            "/home/user/project/.build/x86_64-apple-macosx/release/mytool"
        ]
        
        for path in paths {
            let (sut, _) = makeSUT(runResults: ["", testSha256])
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            
            let result = try sut.createArchives(from: [path])
            
            #expect(result.count == 1)
            #expect(result[0].archivePath.contains("\(fileName)-x86_64.tar.gz"))
        }
    }
    
    @Test("Uses generic naming for paths without architecture indicators")
    func usesGenericNamingForNonArchPaths() throws {
        let paths = [
            "/usr/local/bin/tool",
            "/home/user/bin/mytool", 
            "/project/build/tool",
            "/simple/path/to/binary"
        ]
        
        for path in paths {
            let (sut, _) = makeSUT(runResults: ["", testSha256])
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            
            let result = try sut.createArchives(from: [path])
            
            #expect(result.count == 1)
            #expect(result[0].archivePath.contains("\(fileName).tar.gz"))
            #expect(!result[0].archivePath.contains("-arm64"))
            #expect(!result[0].archivePath.contains("-x86_64"))
        }
    }
}


// MARK: - SHA256 Parsing Tests
extension BinaryArchiverTests {
    @Test("Correctly parses SHA256 from shasum output")
    func parsesSha256FromShasumOutput() throws {
        let expectedSha256 = "a1b2c3d4e5f6789"
        let shasumOutput = "\(expectedSha256)  /path/to/file.tar.gz"
        let (sut, _) = makeSUT(runResults: ["", shasumOutput])
        
        let result = try sut.createArchives(from: [genericBinaryPath])
        
        #expect(result.count == 1)
        #expect(result[0].sha256 == expectedSha256)
    }
    
    @Test("Handles SHA256 output with multiple spaces")
    func handlesSha256WithMultipleSpaces() throws {
        let expectedSha256 = "a1b2c3d4e5f6789"
        let shasumOutput = "\(expectedSha256)    /path/to/file.tar.gz"
        let (sut, _) = makeSUT(runResults: ["", shasumOutput])
        
        let result = try sut.createArchives(from: [genericBinaryPath])
        
        #expect(result.count == 1)
        #expect(result[0].sha256 == expectedSha256)
    }
}


// MARK: - SUT
private extension BinaryArchiverTests {
    func makeSUT(runResults: [String] = [], throwError: Bool = false) -> (sut: BinaryArchiver, shell: MockShell) {
        let shell = MockShell(results: runResults, shouldThrowError: throwError)
        let sut = BinaryArchiver(shell: shell)
        
        return (sut, shell)
    }
}
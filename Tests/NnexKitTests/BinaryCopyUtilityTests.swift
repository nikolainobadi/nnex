//
//  BinaryCopyUtilityTests.swift
//  NnexKitTests
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Testing
import Foundation
import NnShellTesting
import NnexSharedTestHelpers
@testable import NnexKit

struct BinaryCopyUtilityTests {
    private let executableName = "testExecutable"
    private let desktopPath = "/Users/test/Desktop"
    private let customPath = "/custom/path"
    private let sourcePath = "/source/binary"
}


// MARK: - Tests
extension BinaryCopyUtilityTests {
    @Test("Returns original binary when output location is current directory")
    func returnsOriginalBinaryForCurrentDirectory() throws {
        let (sut, shell) = makeSUT()
        let originalBinary = BinaryOutput.single(sourcePath)
        let outputLocation = BuildOutputLocation.currentDirectory(.universal)

        let result = try sut.copyBinaryToLocation(binaryOutput: originalBinary, outputLocation: outputLocation, executableName: executableName)
        
        if case .single(let path) = result, case .single(let originalPath) = originalBinary {
            #expect(path == originalPath)
        } else {
            Issue.record("Expected single binary output")
        }
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Copies single binary to desktop")
    func copiesSingleBinaryToDesktop() throws {
        let (sut, shell) = makeSUT()
        let originalBinary = BinaryOutput.single(sourcePath)
        let outputLocation = BuildOutputLocation.desktop
        
        _ = try sut.copyBinaryToLocation(binaryOutput: originalBinary, outputLocation: outputLocation, executableName: executableName)
        
        #expect(shell.executedCommands.count == 1)
        #expect(shell.executedCommands.first?.contains("cp") == true)
        #expect(shell.executedCommands.first?.contains(sourcePath) == true)
        #expect(shell.executedCommands.first?.contains("Desktop") == true)
        #expect(shell.executedCommands.first?.contains(executableName) == true)
    }
    
    @Test("Copies single binary to custom location")
    func copiesSingleBinaryToCustomLocation() throws {
        let (sut, shell) = makeSUT()
        let originalBinary = BinaryOutput.single(sourcePath)
        let outputLocation = BuildOutputLocation.custom(customPath)
        
        let result = try sut.copyBinaryToLocation(binaryOutput: originalBinary, outputLocation: outputLocation, executableName: executableName)
        
        #expect(shell.executedCommands.count == 1)
        #expect(shell.executedCommands.first?.contains("cp \"\(sourcePath)\" \"\(customPath)/\(executableName)\"") == true)
        
        if case .single(let path) = result {
            #expect(path == "\(customPath)/\(executableName)")
        } else {
            Issue.record("Expected single binary output")
        }
    }
    
    @Test("Copies multiple binaries to desktop with architecture suffixes")
    func copiesMultipleBinariesToDesktop() throws {
        let (sut, shell) = makeSUT()
        let originalBinary = BinaryOutput.multiple([.arm: "/source/arm64", .intel: "/source/x86_64"])
        let outputLocation = BuildOutputLocation.desktop
        
        try sut.copyBinaryToLocation(binaryOutput: originalBinary, outputLocation: outputLocation, executableName: executableName)
        
        #expect(shell.executedCommands.count == 2)
        
        let commands = shell.executedCommands
        #expect(commands.contains { $0.contains("arm64") && $0.contains("\(executableName)-arm64") })
        #expect(commands.contains { $0.contains("x86_64") && $0.contains("\(executableName)-x86_64") })
    }
    
    @Test("Copies multiple binaries to custom location with architecture suffixes")
    func copiesMultipleBinariesToCustomLocation() throws {
        let (sut, shell) = makeSUT()
        let originalBinary = BinaryOutput.multiple([.arm: "/source/arm64", .intel: "/source/x86_64"])
        let outputLocation = BuildOutputLocation.custom(customPath)
        let result = try sut.copyBinaryToLocation(binaryOutput: originalBinary, outputLocation: outputLocation, executableName: executableName)
        
        #expect(shell.executedCommands.count == 2)
        
        if case .multiple(let binaries) = result {
            #expect(binaries[.arm] == "\(customPath)/\(executableName)-arm64")
            #expect(binaries[.intel] == "\(customPath)/\(executableName)-x86_64")
        } else {
            Issue.record("Expected multiple binary output")
        }
    }
    
    @Test("Preserves paths with spaces using proper quoting")
    func preservesPathsWithSpaces() throws {
        let (sut, shell) = makeSUT()
        let sourceWithSpaces = "/path with/spaces/binary"
        let destinationWithSpaces = "/destination with/spaces"
        let originalBinary = BinaryOutput.single(sourceWithSpaces)
        let outputLocation = BuildOutputLocation.custom(destinationWithSpaces)
        
        try sut.copyBinaryToLocation(binaryOutput: originalBinary, outputLocation: outputLocation, executableName: executableName)
        
        #expect(shell.executedCommands.count == 1)
        #expect(shell.executedCommands.first?.contains("cp \"\(sourceWithSpaces)\" \"\(destinationWithSpaces)/\(executableName)\"") == true)
    }
    
    @Test("Throws error when shell command fails")
    func throwsErrorWhenShellCommandFails() throws {
        let sut = makeSUT(throwError: true).sut
        let originalBinary = BinaryOutput.single(sourcePath)
        let outputLocation = BuildOutputLocation.desktop
        
        #expect(throws: (any Error).self) {
            try sut.copyBinaryToLocation(binaryOutput: originalBinary, outputLocation: outputLocation, executableName: executableName)
        }
    }
}


// MARK: - Private Methods
private extension BinaryCopyUtilityTests {
    func makeSUT(throwError: Bool = false) -> (sut: BinaryCopyUtility, shell: MockShell) {
        let fileSystem = MockFileSystem()
        let shell = MockShell(shouldThrowErrorOnFinal: throwError)
        let sut = BinaryCopyUtility(shell: shell, fileSystem: fileSystem)

        return (sut, shell)
    }
}

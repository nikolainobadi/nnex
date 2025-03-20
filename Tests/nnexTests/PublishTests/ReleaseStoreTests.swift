//
//  ReleaseStoreTests.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Testing
@testable import nnex

struct ReleaseStoreTests {
    @Test("Uploads a release and returns binary URL")
    func uploadRelease() throws {
        let mockShell = MockShell(runResults: ["https://github.com/test/binary1"])
        let mockPicker = MockPicker(inputResponses: ["Release notes for version 1.0.0"])
        let store = ReleaseStore(shell: mockShell, picker: mockPicker)
        let info = ReleaseInfo(binaryPath: "path/to/binary", projectPath: "path/to/project", versionInfo: .version("1.0.0"))
        let result = try store.uploadRelease(info: info)
        
        #expect(result == "https://github.com/test/binary1")
        #expect(mockShell.printedCommands.contains("gh release create 1.0.0 path/to/binary --title \"1.0.0\" --notes \"Release notes for version 1.0.0\""))
    }
    
    @Test("Throws error if shell command fails during release upload")
    func uploadReleaseShellError() throws {
        let mockShell = MockShell(shouldThrowError: true)
        let mockPicker = MockPicker()
        let store = ReleaseStore(shell: mockShell, picker: mockPicker)
        let info = ReleaseInfo(binaryPath: "path/to/binary", projectPath: "path/to/project", versionInfo: .version("1.0.0"))

        #expect(throws: (any Error).self) {
            try store.uploadRelease(info: info)
        }
    }
}

import Foundation
//@testable import nnex

final class MockShell: Shell {
    private let shouldThrowError: Bool
    private let errorMessage = "MockShell error"
    private var runResults: [String]
    private(set) var printedCommands: [String] = []
    
    init(runResults: [String] = [], shouldThrowError: Bool = false) {
        self.runResults = runResults
        self.shouldThrowError = shouldThrowError
    }

    func run(_ command: String) throws -> String {
        printedCommands.append(command)
        if shouldThrowError {
            throw NSError(domain: "MockShell", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return runResults.isEmpty ? "" : runResults.removeFirst()
    }

    func runAndPrint(_ command: String) throws {
        printedCommands.append(command)
        if shouldThrowError {
            throw NSError(domain: "MockShell", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
}

import Foundation
import SwiftPicker
//@testable import nnex

final class MockPicker: Picker {
    private let shouldThrowError: Bool
    private let errorMessage = "MockPicker error"
    private var permissionResponses: [Bool]
    private var inputResponses: [String]
    
    init(permissionResponses: [Bool] = [], inputResponses: [String] = [], shouldThrowError: Bool = false) {
        self.shouldThrowError = shouldThrowError
        self.permissionResponses = permissionResponses
        self.inputResponses = inputResponses
    }
    
    func requiredPermission(prompt: String) throws {
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }

    func getPermission(_ type: PermissionType) -> Bool {
        return permissionResponses.isEmpty ? false : permissionResponses.removeFirst()
    }

    func getRequiredInput(_ type: InputType) throws -> String {
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return inputResponses.isEmpty ? "" : inputResponses.removeFirst()
    }

    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item {
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return items.first!
    }
}

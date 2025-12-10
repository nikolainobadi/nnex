//
//  MockDirectory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import NnexKit
import Foundation

public final class MockDirectory: Directory {
    private let shouldThrowOnSubdirectory: Bool
    private let autoCreateSubdirectories: Bool

    public let path: String
    public let name: String
    public let `extension`: String?
    public var subdirectories: [any Directory]
    public var containedFiles: Set<String>
    public var fileContents: [String: String] = [:]
    public private(set) var movedToParents: [String] = []
    
    public init(path: String, subdirectories: [any Directory] = [], containedFiles: Set<String> = [], shouldThrowOnSubdirectory: Bool = false, autoCreateSubdirectories: Bool = true, ext: String? = nil) {
        self.path = path
        self.name = (path as NSString).lastPathComponent
        self.subdirectories = subdirectories
        self.containedFiles = containedFiles
        self.shouldThrowOnSubdirectory = shouldThrowOnSubdirectory
        self.autoCreateSubdirectories = autoCreateSubdirectories
        self.extension = ext
    }

    public func containsFile(named name: String) -> Bool {
        return containedFiles.contains(name)
    }

    public func subdirectory(named name: String) throws -> any Directory {
        if shouldThrowOnSubdirectory {
            throw NSError(domain: "MockDirectory", code: 1)
        }

        if let match = subdirectories.first(where: { $0.name == name }) {
            return match
        }

        if autoCreateSubdirectories {
            return MockDirectory(path: path.appendingPathComponent(name))
        }

        throw NSError(domain: "MockDirectory", code: 2)
    }

    public func createSubdirectory(named name: String) throws -> any Directory {
        return try subdirectory(named: name)
    }

    public func move(to parent: any Directory) throws {
        movedToParents.append(parent.path)
    }

    public func createSubfolderIfNeeded(named name: String) throws -> any Directory {
        if let existing = subdirectories.first(where: { $0.name == name }) {
            return existing
        }
        let newSubdirectory = MockDirectory(path: path.appendingPathComponent(name))
        subdirectories.append(newSubdirectory)
        return newSubdirectory
    }

    public func deleteFile(named name: String) throws {
        containedFiles.remove(name)
    }

    @discardableResult
    public func createFile(named name: String, contents: String) throws -> String {
        containedFiles.insert(name)
        fileContents[name] = contents
        return path.appendingPathComponent(name)
    }

    public func readFile(named name: String) throws -> String {
        guard containedFiles.contains(name) else {
            throw NSError(domain: "MockDirectory", code: 3, userInfo: [NSLocalizedDescriptionKey: "File not found: \(name)"])
        }
        return fileContents[name] ?? ""
    }

    public func findFiles(withExtension extension: String?, recursive: Bool) throws -> [String] {
        var filePaths: [String] = []

        // Add files from current directory
        for fileName in containedFiles {
            if let ext = `extension` {
                let fileExt = (fileName as NSString).pathExtension
                if fileExt == ext {
                    filePaths.append(path.appendingPathComponent(fileName))
                }
            } else {
                filePaths.append(path.appendingPathComponent(fileName))
            }
        }

        // Recursively search subdirectories if requested
        if recursive {
            for subdirectory in subdirectories {
                let subFiles = try subdirectory.findFiles(withExtension: `extension`, recursive: true)
                filePaths.append(contentsOf: subFiles)
            }
        }

        return filePaths
    }
}

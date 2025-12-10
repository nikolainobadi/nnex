//
//  MockFileSystem.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import NnexKit
import Foundation

public final class MockFileSystem: FileSystem {
    private let desktop: any Directory
    private let directoryToLoad: (any Directory)?
    private let directoryMap: [String: any Directory]?

    public private(set) var capturedPaths: [String] = []
    public private(set) var pathToMoveToTrash: String?

    public let homeDirectory: any Directory
    public var currentDirectory: any Directory

    public init(
        homeDirectory: any Directory = MockDirectory(path: "/Users/Home"),
        currentDirectory: any Directory = MockDirectory(path: "/Users/Home/CurrentTest"),
        directoryToLoad: (any Directory)? = nil,
        directoryMap: [String: any Directory]? = nil,
        desktop: (any Directory)? = nil
    ) {
        self.homeDirectory = homeDirectory
        self.currentDirectory = currentDirectory
        self.directoryToLoad = directoryToLoad
        self.directoryMap = directoryMap
        self.desktop = desktop ?? MockDirectory(path: homeDirectory.path.appendingPathComponent("Desktop"))
    }

    public func directory(at path: String) throws -> any Directory {
        capturedPaths.append(path)

        if let directoryMap, let directory = directoryMap[path] {
            return directory
        }

        if let directoryToLoad {
            return directoryToLoad
        }

        throw NSError(domain: "MockFileSystem", code: 1)
    }

    public func desktopDirectory() throws -> any Directory {
        return desktop
    }

    public func readFile(at path: String) throws -> String {
        // Extract directory path and filename
        let directoryPath = (path as NSString).deletingLastPathComponent
        let fileName = (path as NSString).lastPathComponent

        let directory = try self.directory(at: directoryPath)
        return try directory.readFile(named: fileName)
    }

    public func writeFile(at path: String, contents: String) throws {
        // Extract directory path and filename
        let directoryPath = (path as NSString).deletingLastPathComponent
        let fileName = (path as NSString).lastPathComponent

        let directory = try self.directory(at: directoryPath)

        // For mock, we update the file if it exists, otherwise create it
        if let mockDir = directory as? MockDirectory {
            mockDir.fileContents[fileName] = contents
            mockDir.containedFiles.insert(fileName)
        }
    }
    
    public func moveToTrash(at path: String) throws {
        pathToMoveToTrash = path
    }
}

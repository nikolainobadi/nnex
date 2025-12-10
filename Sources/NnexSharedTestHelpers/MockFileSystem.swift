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

    public let homeDirectory: any Directory

    public init(homeDirectory: any Directory = MockDirectory(path: "/Users/test"), directoryToLoad: (any Directory)? = nil, directoryMap: [String: any Directory]? = nil, desktop: (any Directory)? = nil) {
        self.homeDirectory = homeDirectory
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
}

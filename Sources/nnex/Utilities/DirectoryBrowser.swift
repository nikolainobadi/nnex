//
//  DirectoryBrowser.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

import NnexKit

// TODO: - maybe add FileSystem conformance?
protocol DirectoryBrowser {
    typealias FilePath = String
    func browseForFile(prompt: String) throws -> FilePath
    func browseForDirectory(prompt: String) throws -> any Directory
}

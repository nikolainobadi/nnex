//
//  DirectoryBrowser.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

import NnexKit

protocol DirectoryBrowser {
    func browseForDirectory(prompt: String) throws -> any Directory
}

//
//  DefaultDirectoryBrowser.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

import NnexKit
import Foundation
import SwiftPickerKit

struct DefaultDirectoryBrowser {
    private let picker: any NnexPicker
    private let fileSystem: any FileSystem
    private let homeDirectoryURL: URL
    
    /// Initializes a new directory browser.
    /// - Parameters:
    ///   - picker: Picker used to drive the interactive tree navigation.
    ///   - fileSystem: File system used to resolve selected directories.
    ///   - homeDirectoryURL: Default root directory for browsing.
    init(picker: any NnexPicker, fileSystem: any FileSystem, homeDirectoryURL: URL) {
        self.picker = picker
        self.fileSystem = fileSystem
        self.homeDirectoryURL = homeDirectoryURL
    }
}


// MARK: - DirectoryBrowser
extension DefaultDirectoryBrowser: DirectoryBrowser {
    func browseForFile(prompt: String) throws -> FilePath {
        return try treeNavigation(prompt: prompt, selectionType: .onlyFiles).url.path()
    }
    
    /// Presents an interactive browser for selecting a directory.
    /// - Parameters:
    ///   - prompt: Prompt shown at the top of the tree navigation.
    ///   - startPath: Optional path to use as the root of the browser. Defaults to the user's home directory.
    /// - Returns: The selected `Directory`.
    func browseForDirectory(prompt: String) throws -> any Directory {
        let selection = try treeNavigation(prompt: prompt, selectionType: .onlyFolders)
        
        return try fileSystem.directory(at: selection.url.path)
    }
}

// MARK: - Private Methods
private extension DefaultDirectoryBrowser {
    func treeNavigation(prompt: String, selectionType: FileSystemNode.SelectionType) throws -> FileSystemNode {
        guard let selection = picker.browseDirectories(prompt: prompt, startURL: homeDirectoryURL, showPromptText: true, showSelectedItemText: true, selectionType: selectionType) else {
            throw NnexError.selectionRequired
        }
        
        return selection
    }
}




//
//  DefaultPicker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Files
import NnexKit
import SwiftPickerKit

/// A default implementation of the `Picker` protocol that utilizes `SwiftPicker`.
struct DefaultPicker {
    private let picker = SwiftPicker()
}


// MARK: - NnexPicker
extension DefaultPicker: NnexPicker {
    /// Requests the user to grant permission for a specific action.
    /// - Parameter prompt: The message to display when asking for permission.
    /// - Throws: An error if the permission request fails.
    func requiredPermission(prompt: String) throws {
        try picker.requiredPermission(prompt: prompt)
    }
    
    /// Checks whether the user grants permission for a specific action.
    /// - Parameter prompt: The message to display when asking for permission.
    /// - Returns: A boolean value indicating whether the permission was granted.
    func getPermission(prompt: String) -> Bool {
        return picker.getPermission(prompt: prompt)
    }
    
    /// Retrieves a required input from the user.
    /// - Parameter prompt: The message to display when asking for input.
    /// - Returns: The user's input as a string.
    /// - Throws: An error if the input could not be obtained.
    func getRequiredInput(prompt: String) throws -> String {
        return try picker.getRequiredInput(prompt: prompt)
    }
    
    /// Presents a single selection picker to the user and returns the chosen item.
    /// - Parameters:
    ///   - title: The title of the selection prompt.
    ///   - items: An array of items to display for selection.
    /// - Returns: The item selected by the user.
    /// - Throws: An error if the selection could not be made.
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item {
        return try picker.requiredSingleSelection(title, items: items, showSelectedItemText: false)
    }
    
    func browseSelection(prompt: String, allowSelectingFolders: Bool) -> FileSystemNode? {
        let homeFolder = Folder.home
        let rootItem = FileSystemNode(url: homeFolder.url)
        
        return picker.treeNavigation(prompt, rootItems: [rootItem], allowSelectingFolders: allowSelectingFolders, startInsideFirstRoot: true)
    }
}

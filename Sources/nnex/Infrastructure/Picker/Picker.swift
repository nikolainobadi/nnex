//
//  Picker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/23/25.
//

import Files
import SwiftPickerKit

/// A protocol defining methods for user interaction and input retrieval.
protocol NnexPicker {
    /// Requests permission from the user with a given prompt.
    /// - Parameter prompt: The message to display when asking for permission.
    /// - Returns: A boolean value indicating whether the permission was granted.
    func getPermission(prompt: String) -> Bool
    
    /// Requests the user to grant permission for a specific action.
    /// - Parameter prompt: The message to display when asking for permission.
    /// - Throws: An error if the permission request fails.
    func requiredPermission(prompt: String) throws
    
    /// Retrieves a required input from the user.
    /// - Parameter prompt: The message to display when asking for input.
    /// - Returns: The user's input as a string.
    /// - Throws: An error if the input could not be obtained.
    func getRequiredInput(prompt: String) throws -> String
    
    /// Presents a single selection picker to the user and returns the chosen item.
    /// - Parameters:
    ///   - title: The title of the selection prompt.
    ///   - items: An array of items to display for selection.
    /// - Returns: The item selected by the user.
    /// - Throws: An error if the selection could not be made.
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item
    
    func browseFolders(prompt: String) -> Folder?
}

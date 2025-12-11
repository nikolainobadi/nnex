//
//  Picker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/23/25.
//

import NnexKit
import Foundation
import SwiftPickerKit

protocol NnexPicker {
    func getPermission(prompt: String) -> Bool
    func requiredPermission(prompt: String) throws
    func getRequiredInput(prompt: String) throws -> String
    func browseDirectories(prompt: String, startURL: URL, showPromptText: Bool, showSelectedItemText: Bool, selectionType: FileSystemNode.SelectionType) -> FileSystemNode?
    func treeNavigation<Item: TreeNodePickerItem>(prompt: String, root: TreeNavigationRoot<Item>, showPromptText: Bool, showSelectedItemText: Bool) -> Item?
    func requiredSingleSelection<Item: DisplayablePickerItem>(prompt: String, items: [Item], layout: PickerLayout<Item>, newScreen: Bool, showSelectedItemText: Bool) throws -> Item
}

extension NnexPicker {
    func requiredSingleSelection<Item: DisplayablePickerItem>(_ prompt: String, items: [Item], layout: PickerLayout<Item> = .singleColumn, newScreen: Bool = true, showSelectedItemText: Bool = true) throws -> Item {
        return try requiredSingleSelection(prompt: prompt, items: items, layout: layout, newScreen: newScreen, showSelectedItemText: showSelectedItemText)
    }
    
    func treeNavigation<Item: TreeNodePickerItem>(_ prompt: String, root: TreeNavigationRoot<Item>, showPromptText: Bool = true, showSelectedItemText: Bool = true) -> Item? {
        return treeNavigation(prompt: prompt, root: root, showPromptText: showPromptText, showSelectedItemText: showSelectedItemText)
    }
    
    func requiredTreeNavigation<Item: TreeNodePickerItem>(_ prompt: String, root: TreeNavigationRoot<Item>, showPromptText: Bool = true, showSelectedItemText: Bool = true) throws -> Item {
        guard let selection = treeNavigation(prompt, root: root) else {
            throw NnexError.selectionRequired
        }
        
        return selection
    }
}

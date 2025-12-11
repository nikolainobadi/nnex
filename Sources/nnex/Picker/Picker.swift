//
//  Picker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/23/25.
//

import Files
import NnexKit
import Foundation
import SwiftPickerKit

protocol NnexPicker {
    func getPermission(prompt: String) -> Bool
    func requiredPermission(prompt: String) throws
    func getRequiredInput(prompt: String) throws -> String
    func browseDirectories(prompt: String, startURL: URL, showPromptText: Bool, showSelectedItemText: Bool, selectionType: FileSystemNode.SelectionType) -> FileSystemNode?
    func treeNavigation<Item: TreeNodePickerItem>(prompt: String, root: TreeNavigationRoot<Item>, newScreen: Bool, showPromptText: Bool, showSelectedItemText: Bool) -> Item?
    func requiredSingleSelection<Item: DisplayablePickerItem>(prompt: String, items: [Item], layout: PickerLayout<Item>, newScreen: Bool, showSelectedItemText: Bool) throws -> Item
}

extension NnexPicker {
    func requiredSingleSelection<Item: DisplayablePickerItem>(_ prompt: String, items: [Item], layout: PickerLayout<Item> = .singleColumn, newScreen: Bool = true, showSelectedItemText: Bool = true) throws -> Item {
        return try requiredSingleSelection(prompt: prompt, items: items, layout: layout, newScreen: newScreen, showSelectedItemText: showSelectedItemText)
    }
    
    func treeNavigation<Item: TreeNodePickerItem>(_ prompt: String, root: TreeNavigationRoot<Item>, newScreen: Bool = true, showPromptText: Bool = true, showSelectedItemText: Bool = true) -> Item? {
        return treeNavigation(prompt: prompt, root: root, newScreen: newScreen, showPromptText: showPromptText, showSelectedItemText: showSelectedItemText)
    }
    
    func requiredTreeNavigation<Item: TreeNodePickerItem>(_ prompt: String, root: TreeNavigationRoot<Item>, newScreen: Bool = true, showPromptText: Bool = true, showSelectedItemText: Bool = true) throws -> Item {
        guard let selection = treeNavigation(prompt, root: root) else {
            throw NnexError.selectionRequired
        }
        
        return selection
    }
    
    func requiredFolderSelection(prompt: String) throws -> Folder {
        let homeFolder = Folder.home
        let folder = try requiredTreeNavigation(prompt, root: .init(displayName: homeFolder.name, children: homeFolder.loadChildren()))
        
        // TODO: - this may need to be adjusted
        return try .init(path: folder.url.path())
    }
}

extension Folder: @retroactive DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}
extension Folder: @retroactive TreeNodePickerItem {
    public var hasChildren: Bool {
        return subfolders.count() > 0
    }
    
    public func loadChildren() -> [Folder] {
        return subfolders.map({ $0 })
    }
    
    public var metadata: TreeNodeMetadata? {
        return nil
    }
    
    public var isSelectable: Bool {
        return true
    }
}

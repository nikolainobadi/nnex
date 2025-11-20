//
//  MockSwiftPicker+NnexPicker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 11/20/25.
//

import Files
import SwiftPickerKit
import SwiftPickerTesting
@testable import nnex

extension MockSwiftPicker: NnexPicker {
    public func browseFolders(prompt: String) -> Folder? {
        return nil // TODO: - 
    }
    
    public func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item {
        return try requiredSingleSelection(prompt: title, items: items, layout: .singleColumn, newScreen: true)
    }
}

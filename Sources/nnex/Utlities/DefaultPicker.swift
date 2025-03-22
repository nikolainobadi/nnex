//
//  DefaultPicker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnexKit
import SwiftPicker

struct DefaultPicker {
    private let picker = SwiftPicker()
}


// MARK: - Picker
extension DefaultPicker: Picker {
    func requiredPermission(prompt: String) throws {
        try picker.requiredPermission(prompt: prompt)
    }
    
    func getPermission(prompt: String) -> Bool {
        return picker.getPermission(prompt: prompt)
    }
    
    func getRequiredInput(prompt: String) throws -> String {
        return try picker.getRequiredInput(prompt)
    }
    
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item {
        return try picker.requiredSingleSelection(title: title, items: items)
    }
}


// MARK: - Dependencies
protocol Picker {
    func getPermission(prompt: String) -> Bool
    func requiredPermission(prompt: String) throws
    func getRequiredInput(prompt: String) throws -> String
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item
}


// MARK: - DisplayablePickerItem
extension SwiftDataTap: DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}

extension SwiftDataFormula: DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}

extension BuildType: DisplayablePickerItem {
    public var displayName: String {
        switch self {
        case .universal:
            return "\(rawValue) (recommended)"
        default:
            return rawValue
        }
    }
}

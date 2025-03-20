//
//  DefaultPicker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import SwiftPicker

struct DefaultPicker {
    private let picker = SwiftPicker()
}


// MARK: - Picker
extension DefaultPicker: Picker {
    func getPermission(_ type: PermissionType) -> Bool {
        return picker.getPermission(prompt: type.prompt)
    }
    
    func getRequiredInput(_ type: InputType) throws -> String {
        return try picker.getRequiredInput(type.prompt)
    }
    
    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item {
        return try picker.requiredSingleSelection(title: title, items: items)
    }
}


// MARK: - DisplayablePickerItem
extension SwiftDataTap: DisplayablePickerItem {
    var displayName: String {
        return name
    }
}

extension SwiftDataFormula: DisplayablePickerItem {
    var displayName: String {
        return name
    }
}

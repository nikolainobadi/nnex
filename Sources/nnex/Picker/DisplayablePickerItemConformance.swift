//
//  DisplayablePickerItemConformance.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/23/25.
//

import NnexKit
import SwiftPicker

extension SwiftDataTap: @retroactive DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}

extension SwiftDataFormula: @retroactive DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}

extension BuildType: @retroactive DisplayablePickerItem {
    public var displayName: String {
        switch self {
        case .universal:
            return "\(rawValue) (recommended)"
        default:
            return rawValue
        }
    }
}

extension NoteContentType: DisplayablePickerItem {
    var displayName: String {
        switch self {
        case .direct:
            return "Type notes directly"
        case .fromPath:
            return "Enter path to release notes file"
        case .createFile:
            return "Create a new file"
        }
    }
}

extension FormulaTestType: DisplayablePickerItem {
    var displayName: String {
        switch self {
        case .custom:
            return "ADD CUSTOM COMMAND"
        case .packageDefault:
            return "Default Commmand (swift test)"
        case .noTests:
            return "Don't include tests"
        }
    }
}

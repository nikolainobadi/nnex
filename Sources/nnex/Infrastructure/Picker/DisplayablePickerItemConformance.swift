//
//  DisplayablePickerItemConformance.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/23/25.
//

import NnexKit
import SwiftPicker

extension SwiftDataTap: DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}

extension SwiftDataFormula:  DisplayablePickerItem {
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

extension ReleaseNotesHandler.NoteContentType: DisplayablePickerItem {
    var displayName: String {
        switch self {
        case .direct:
            return "Type notes directly"
        case .fromPath:
            return "Enter path to release notes file"
        case .createFile:
            return "Create a new file"
        case .aiGenerated:
            return "Generate with AI"
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

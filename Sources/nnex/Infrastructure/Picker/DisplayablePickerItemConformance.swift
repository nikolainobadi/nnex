//
//  DisplayablePickerItemConformance.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/23/25.
//

import NnexKit
import SwiftPickerKit

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

extension BuildOutputLocation: DisplayablePickerItem {
    public var displayName: String {
        switch self {
        case .currentDirectory(let buildType):
            return "Current directory (.build/\(buildType.rawValue))"
        case .desktop:
            return "Desktop"
        case .custom:
            return "Custom location..."
        }
    }
}

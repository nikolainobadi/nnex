//
//  DisplayablePickerItemConformance.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/23/25.
//

import NnexKit
import SwiftPickerKit

// MARK: - HomebrewTap
extension HomebrewTap: DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}


// MARK: - HomebrewFormula
extension HomebrewFormula: DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}


// MARK: - BuildType
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


// MARK: - BuildOutputLocation
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


// MARK: - FormulaTestType
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


// MARK: - SwiftDataHomebrewTap
extension SwiftDataHomebrewTap: DisplayablePickerItem {
    public var displayName: String {
        return name
    }
}


// MARK: - NoteContentType
extension NoteContentType: DisplayablePickerItem {
    var displayName: String {
        switch self {
        case .direct:
            return "Type notes directly"
        case .selectFile:
            return "Browse and select file"
        case .fromPath:
            return "Enter path to release notes file"
        case .createFile:
            return "Create a new file"
        }
    }
}

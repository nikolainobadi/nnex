//
//  BuildOutputLocation.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import NnexKit
import SwiftPicker

enum BuildOutputLocation {
    case currentDirectory(BuildType)
    case desktop
    case custom(String)
}

extension BuildOutputLocation: DisplayablePickerItem {
    var displayName: String {
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

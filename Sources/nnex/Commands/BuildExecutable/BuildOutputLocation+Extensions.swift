//
//  BuildOutputLocation.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import NnexKit
import SwiftPicker

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

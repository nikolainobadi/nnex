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

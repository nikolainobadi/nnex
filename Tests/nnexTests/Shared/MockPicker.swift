//
//  MockPicker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Foundation
import SwiftPicker
@testable import nnex

final class MockPicker {
    private let shouldThrowError: Bool
    private let errorMessage = "MockPicker error"
    private var permissionResponses: [Bool]
    private var inputResponses: [String]
    
    init(permissionResponses: [Bool] = [], inputResponses: [String] = [], shouldThrowError: Bool = false) {
        self.shouldThrowError = shouldThrowError
        self.permissionResponses = permissionResponses
        self.inputResponses = inputResponses
    }
}


// MARK: - Picker
extension MockPicker: Picker {
    func requiredPermission(prompt: String) throws {
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }

    func getPermission(_ type: PermissionType) -> Bool {
        return permissionResponses.isEmpty ? false : permissionResponses.removeFirst()
    }

    func getRequiredInput(_ type: InputType) throws -> String {
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return inputResponses.isEmpty ? "" : inputResponses.removeFirst()
    }

    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item {
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return items.first!
    }
}

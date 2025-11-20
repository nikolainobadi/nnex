//
//  MockPicker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Foundation
import SwiftPickerKit
@testable import nnex

final class MockPicker {
    private var selectedItemIndices: [Int]
    private let shouldThrowError: Bool
    private let errorMessage = "MockPicker error"
    private var inputResponses: [String]
    private var permissionResponses: [Bool]
    
    // Track prompts for testing
    private(set) var lastPrompt: String?
    private(set) var allPrompts: [String] = []
    
    init(selectedItemIndex: Int = 0, selectedItemIndices: [Int] = [], inputResponses: [String] = [], permissionResponses: [Bool] = [], shouldThrowError: Bool = false) {
        // Use selectedItemIndices if provided, otherwise use repeated selectedItemIndex
        self.selectedItemIndices = selectedItemIndices.isEmpty ? [selectedItemIndex] : selectedItemIndices
        self.shouldThrowError = shouldThrowError
        self.inputResponses = inputResponses
        self.permissionResponses = permissionResponses
    }
}


// MARK: - NnexPicker
extension MockPicker: NnexPicker {
    func requiredPermission(prompt: String) throws {
        lastPrompt = prompt
        allPrompts.append(prompt)
        
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }

    func getPermission(prompt: String) -> Bool {
        lastPrompt = prompt
        allPrompts.append(prompt)
        
        return permissionResponses.isEmpty ? false : permissionResponses.removeFirst()
    }

    func getRequiredInput(prompt: String) throws -> String {
        lastPrompt = prompt
        allPrompts.append(prompt)
        
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        return inputResponses.isEmpty ? "" : inputResponses.removeFirst()
    }

    func requiredSingleSelection<Item: DisplayablePickerItem>(title: String, items: [Item]) throws -> Item {
        lastPrompt = title
        allPrompts.append(title)
        
        if shouldThrowError {
            throw NSError(domain: "MockPicker", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        let index = selectedItemIndices.isEmpty ? 0 : selectedItemIndices.removeFirst()
        return items[index]
    }
}

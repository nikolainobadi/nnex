//
//  ContextFactory.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

protocol ContextFactory {
    func makePicker() -> Picker
    func makeContext() throws -> SharedContext
}

protocol Picker {
    func getRequiredInput(_ prompt: String) throws -> String
}


// MARK: - Default Factory
struct DefaultContextFactory: ContextFactory {
    func makePicker() -> any Picker {
        return DefaultPicker()
    }
    
    func makeContext() throws -> SharedContext {
        return try SharedContext()
    }
}

import SwiftPicker

struct DefaultPicker {
    private let picker = SwiftPicker()
}

extension DefaultPicker: Picker {
    func getRequiredInput(_ prompt: String) throws -> String {
        return try picker.getRequiredInput(prompt)
    }
}

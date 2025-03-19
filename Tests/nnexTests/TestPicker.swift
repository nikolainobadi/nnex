//
//  TestPicker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

@testable import nnex

struct TestPicker {
    private let inputProvider: (InputType) -> String
    
    init(inputProvider: @escaping (InputType) -> String) {
        self.inputProvider = inputProvider
    }
}


// MARK: - Picker
extension TestPicker: Picker {
    func getRequiredInput(_ type: InputType) throws -> String {
        return inputProvider(type)
    }
}

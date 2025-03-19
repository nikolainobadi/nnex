//
//  TestPicker.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

@testable import nnex

struct TestPicker {
    private let inputProvider: (InputType) -> String
    private let permissionProvider: (PermissionType) -> Bool
    
    init(inputProvider: @escaping (InputType) -> String, permissionProvider: @escaping (PermissionType) -> Bool) {
        self.inputProvider = inputProvider
        self.permissionProvider = permissionProvider
    }
}


// MARK: - Picker
extension TestPicker: Picker {
    func getPermission(_ type: PermissionType) -> Bool {
        return permissionProvider(type)
    }
    
    func getRequiredInput(_ type: InputType) throws -> String {
        return inputProvider(type)
    }
}

//
//  MockTrashHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/20/25.
//

import Foundation
@testable import nnex

final class MockTrashHandler: TrashHandler {
    var moveToTrashCalled = false
    var lastMovedPath: String?
    var shouldThrowError = false
    
    func moveToTrash(at path: String) throws {
        moveToTrashCalled = true
        lastMovedPath = path
        
        if shouldThrowError {
            throw NSError(domain: "MockTrashHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }
}
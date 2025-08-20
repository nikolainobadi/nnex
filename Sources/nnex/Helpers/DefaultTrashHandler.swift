//
//  DefaultTrashHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/20/25.
//

import Foundation

struct DefaultTrashHandler: TrashHandler {
    func moveToTrash(at path: String) throws {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)
        try fileManager.trashItem(at: url, resultingItemURL: nil)
    }
}

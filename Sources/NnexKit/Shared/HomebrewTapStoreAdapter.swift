//
//  HomebrewTapStoreAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

public struct HomebrewTapStoreAdapter {
    private let context: NnexContext
    
    public init(context: NnexContext) {
        self.context = context
    }
}


// MARK: - HomebrewTapStore
extension HomebrewTapStoreAdapter: HomebrewTapStore {
    public func saveTapListFolderPath(path: String) {
        context.saveTapListFolderPath(path: path)
    }
    
    public func saveNewTap(_ tap: HomebrewTap) throws {
        try context.saveNewTap(HomebrewTapMapper.toSwiftData(tap))
    }
}

//
//  HomebrewTapManager.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

public struct HomebrewTapManager {
    private let store: any HomebrewTapStore
    private let gitHandler: any GitHandler
    
    public init(store: any HomebrewTapStore, gitHandler: any GitHandler) {
        self.store = store
        self.gitHandler = gitHandler
    }
}


// MARK: - CreateTap
extension HomebrewTapManager: HomebrewTapService {
    public func saveTapListFolderPath(path: String) {
        store.saveTapListFolderPath(path: path)
    }
    
    public func createNewTap(named name: String, details: String, in parentFolder: any Directory, isPrivate: Bool) throws {
        try gitHandler.ghVerification()
        
        let tapFolder = try createTapFolder(named: name, in: parentFolder)
        let remotePath = try createRemoteRepository(folder: tapFolder, details: details, isPrivate: isPrivate)
        
        try store.saveNewTap(.init(folder: tapFolder, remotePath: remotePath))
    }
}


// MARK: - Private Methods
private extension HomebrewTapManager {
    func createTapFolder(named name: String, in parentFolder: any Directory) throws -> any Directory {
        let homebrewTapName = name.homebrewTapName
        let tapFolder = try parentFolder.createSubfolderIfNeeded(named: homebrewTapName)
        
        _ = try tapFolder.createSubfolderIfNeeded(named: "Formula")
        
        return tapFolder
    }
    
    func createRemoteRepository(folder: any Directory, details: String, isPrivate: Bool) throws -> String {
        let path = folder.path
        try gitHandler.gitInit(path: path)
        return try gitHandler.remoteRepoInit(tapName: folder.name, path: path, projectDetails: details, visibility: isPrivate ? .privateRepo : .publicRepo)
    }
}


// MARK: - Dependencies
public protocol HomebrewTapStore {
    func saveTapListFolderPath(path: String)
    func saveNewTap(_ tap: HomebrewTap) throws
}


// MARK: - Extension Dependencies
private extension HomebrewTap {
    init(folder: any Directory, remotePath: String) {
        self.init(name: folder.name, localPath: folder.path, remotePath: remotePath, formulas: [])
    }
}

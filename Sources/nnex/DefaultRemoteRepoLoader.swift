//
//  DefaultRemoteRepoLoader.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import NnGitKit

struct DefaultRemoteRepoLoader {
    private let manager = GitKitRepositoryManager()
}


// MARK: - Loader
extension DefaultRemoteRepoLoader: RemoteRepoLoader {
    func getGitHubURL(path: String?) -> String {
        return manager.getGitHubURL(path: path)
    }
}

//
//  RepoInfoProviderAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import GitShellKit

struct RepoInfoProviderAdapter {
    private let picker: Picker
    private let tapName: String
    private let projectDetails: String?
    private let visibility: RepoVisibility
    
    init(picker: Picker, tapName: String, projectDetails: String?, visibility: RepoVisibility) {
        self.picker = picker
        self.tapName = tapName
        self.projectDetails = projectDetails
        self.visibility = visibility
    }
}


// MARK: - RepoInfoProvider
extension RepoInfoProviderAdapter: RepoInfoProvider {
    func getProjectName() throws -> String {
        return tapName
    }
    
    func getProjectDetails() throws -> String {
        return try projectDetails ?? picker.getRequiredInput(prompt: "Enter details for this new tap.")
    }
    
    func getVisibility() throws -> RepoVisibility {
        return visibility
    }
    
    func canUploadFromNonMainBranch() throws -> Bool {
        return false
    }
}

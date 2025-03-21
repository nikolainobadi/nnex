//
//  RepoInfoProviderAdapter.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/21/25.
//

import SwiftPicker
import GitShellKit

struct RepoInfoProviderAdapter {
    private let picker: Picker
    private let tapName: String
    private let username: String
    private let projectDetails: String?
    
    init(picker: Picker, tapName: String, username: String, projectDetails: String?) {
        self.picker = picker
        self.tapName = tapName
        self.username = username
        self.projectDetails = projectDetails
    }
}


// MARK: - RepoInfoProvider
extension RepoInfoProviderAdapter: RepoInfoProvider {
    func getUsername() throws -> String {
        return username
    }
    
    func getProjectName() throws -> String {
        return tapName
    }
    
    func getProjectDetails() throws -> String {
        return try projectDetails ?? picker.getRequiredInput(prompt: "Enter details for this new tap.")
    }
    
    func getVisibility() throws -> RepoVisibility {
        return try picker.requiredSingleSelection(title: "Select the visibility for this new tap.", items: RepoVisibility.allCases)
    }
}


// MARK: - Extension Dependencies
extension RepoVisibility: @retroactive DisplayablePickerItem {
    public var displayName: String {
        switch self {
        case .publicRepo:
            return "public (recommended)"
        case .privateRepo:
            return "private"
        }
    }
}

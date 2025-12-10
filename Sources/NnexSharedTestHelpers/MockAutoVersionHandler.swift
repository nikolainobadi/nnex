//
//  MockAutoVersionHandler.swift
//  nnex
//
//  Created by Nikolai Nobadi on 8/12/25.
//

import NnexKit
import Foundation

public final class MockAutoVersionHandler: AutoVersionHandling {
    public var detectedVersion: String?
    public var shouldUpdate: Bool = false
    public var updateSucceeds: Bool = true
    public var detectCallCount = 0
    public var shouldUpdateCallCount = 0
    public var updateCallCount = 0

    private var detectedVersions: [String?] = []
    private var currentDetectedIndex = 0

    public init(detectedVersion: String? = nil, shouldUpdate: Bool = false, updateSucceeds: Bool = true) {
        self.detectedVersion = detectedVersion
        self.shouldUpdate = shouldUpdate
        self.updateSucceeds = updateSucceeds
    }

    public func detectArgumentParserVersion(projectPath: String) throws -> String? {
        detectCallCount += 1

        if !detectedVersions.isEmpty && currentDetectedIndex < detectedVersions.count {
            let version = detectedVersions[currentDetectedIndex]
            currentDetectedIndex += 1
            return version
        }

        return detectedVersion
    }

    public func updateArgumentParserVersion(projectPath: String, newVersion: String) throws -> Bool {
        updateCallCount += 1
        return updateSucceeds
    }

    public func shouldUpdateVersion(currentVersion: String, releaseVersion: String) -> Bool {
        shouldUpdateCallCount += 1
        return shouldUpdate
    }

    // Helper method to set multiple detected versions for sequential calls
    public func setDetectedVersions(_ versions: [String?]) {
        detectedVersions = versions
        currentDetectedIndex = 0
    }
}

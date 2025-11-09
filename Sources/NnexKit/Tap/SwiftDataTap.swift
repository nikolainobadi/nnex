//
//  SwiftDataTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import SwiftData

/// Represents a Homebrew Tap with associated formulas.
@Model
public final class SwiftDataTap {
    /// The name of the tap (unique identifier).
    @Attribute(.unique) public var name: String

    /// The local file path of the tap (unique identifier).
    @Attribute(.unique) public var localPath: String

    /// The remote URL of the tap (unique identifier).
    @Attribute(.unique) public var remotePath: String

    /// The list of formulas associated with this tap.
    @Relationship(deleteRule: .cascade, inverse: \SwiftDataFormula.tap) public var formulas: [SwiftDataFormula] = []

    /// Initializes a new SwiftDataTap instance.
    /// - Parameters:
    ///   - name: The name of the tap.
    ///   - localPath: The local file path of the tap.
    ///   - remotePath: The remote URL of the tap.
    public init(name: String, localPath: String, remotePath: String) {
        self.name = name
        self.localPath = localPath
        self.remotePath = remotePath
    }
}

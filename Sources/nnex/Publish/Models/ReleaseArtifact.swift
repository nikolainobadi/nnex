//
//  ReleaseArtifact.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/13/25.
//

import NnexKit

struct ReleaseArtifact {
    let version: String
    let executableName: String
    let archives: [ArchivedBinary]
}

//
//  BuildType.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

/// Represents the build type for a project, specifying the target architecture.
public enum BuildType: String, CaseIterable, Sendable {
    /// Universal build, targeting both ARM and Intel architectures.
    case universal

    /// ARM64 architecture.
    case arm64

    /// x86_64 architecture.
    case x86_64
}

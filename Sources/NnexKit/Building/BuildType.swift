//
//  BuildType.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

public enum BuildType: String, CaseIterable, Sendable {
    case universal
    case arm64
    case x86_64
}

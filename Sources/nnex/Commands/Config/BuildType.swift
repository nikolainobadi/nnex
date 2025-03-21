//
//  BuildType.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import ArgumentParser

enum BuildType: String, CaseIterable, ExpressibleByArgument {
    case universal, arm64, x86_64
}

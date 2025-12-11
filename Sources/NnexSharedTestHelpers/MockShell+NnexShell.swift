//
//  MockShell+NnexShell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import NnexKit
import GitShellKit
import NnShellTesting

extension MockShell: @retroactive GitShell {}
extension MockShell: NnexShell {
    public func runWithOutput(_ command: String) throws -> String {
        return try bash(command)
    }
}

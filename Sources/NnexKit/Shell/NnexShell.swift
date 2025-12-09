//
//  NnexShell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

import GitShellKit

// TODO: - remove GitShell when possible
public protocol NnexShell: GitShell {
    func bash(_ command: String) throws -> String
    func runAndPrint(bash command: String) throws
}

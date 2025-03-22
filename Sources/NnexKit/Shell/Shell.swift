//
//  Shell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

public protocol Shell {
    func run(_ command: String) throws -> String
    func runAndPrint(_ command: String) throws
}

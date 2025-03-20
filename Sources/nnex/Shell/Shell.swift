//
//  Shell.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

protocol Shell {
    func run(_ command: String) throws -> String
    func runAndPrint(_ command: String) throws
}

//
//  FormulaPublisher.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import Files

/// Handles publishing Homebrew formulas to a specified tap.
public struct FormulaPublisher {
    private let gitHandler: GitHandler

    /// Initializes a new instance of FormulaPublisher.
    /// - Parameter gitHandler: The Git handler used to commit and push formula files.
    public init(gitHandler: GitHandler) {
        self.gitHandler = gitHandler
    }
}

// MARK: - Publish
public extension FormulaPublisher {
    /// Publishes a Homebrew formula file to the specified tap.
    /// - Parameters:
    ///   - content: The formula file content as a string.
    ///   - formulaName: The name of the formula file.
    ///   - commitMessage: An optional commit message for publishing the formula.
    ///   - tapFolderPath: The path to the tap folder where the formula will be stored.
    /// - Returns: The file path of the published formula.
    /// - Throws: An error if publishing fails.
    func publishFormula(_ content: String, formulaName: String, commitMessage: String?, tapFolderPath: String) throws -> String {
        let fileName = "\(formulaName).rb"
        let tapFolder = try Folder(path: tapFolderPath)

        if tapFolder.containsFile(named: fileName) {
            try tapFolder.file(named: fileName).delete()
        }

        let newFile = try tapFolder.createFile(named: fileName)
        try newFile.write(content)

        if let commitMessage {
            try gitHandler.commitAndPush(message: commitMessage, path: tapFolderPath)
        }

        return newFile.path
    }
}

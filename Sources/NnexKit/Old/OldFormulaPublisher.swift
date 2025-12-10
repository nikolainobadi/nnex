//
//  FormulaPublisher.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

/// Handles publishing Homebrew formulas to a specified tap.
public struct OldFormulaPublisher {
    private let gitHandler: any GitHandler
    private let fileSystem: any FileSystem

    /// Initializes a new instance of FormulaPublisher.
    /// - Parameters:
    ///   - gitHandler: The Git handler used to commit and push formula files.
    ///   - fileSystem: The file system abstraction for directory and file operations.
    public init(gitHandler: any GitHandler, fileSystem: any FileSystem) {
        self.gitHandler = gitHandler
        self.fileSystem = fileSystem
    }
}

// MARK: - Publish
public extension OldFormulaPublisher {
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
        let tapFolder = try fileSystem.directory(at: tapFolderPath)
        let formulaFolder = try tapFolder.createSubfolderIfNeeded(named: "Formula")

        if formulaFolder.containsFile(named: fileName) {
            try formulaFolder.deleteFile(named: fileName)
        }

        let filePath = try formulaFolder.createFile(named: fileName, contents: content)

        if let commitMessage {
            try gitHandler.commitAndPush(message: commitMessage, path: tapFolderPath)
        }

        return filePath
    }
}

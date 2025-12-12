//
//  BuildResult.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/12/25.
//

public struct BuildResult {
    public let executableName: String
    public let binaryOutput: BinaryOutput
    
    public init(executableName: String, binaryOutput: BinaryOutput) {
        self.executableName = executableName
        self.binaryOutput = binaryOutput
    }
}

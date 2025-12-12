//
//  BinaryOutput.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

public enum BinaryOutput: Equatable {
    public typealias BinaryPath = String
    
    case single(BinaryPath)
    case multiple([ReleaseArchitecture: BinaryPath])
}

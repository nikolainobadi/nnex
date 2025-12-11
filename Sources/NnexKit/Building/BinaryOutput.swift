//
//  BinaryOutput.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/10/25.
//

public enum BinaryOutput {
    public typealias BinaryPath = String
    
    case single(BinaryPath)
    case multiple([ReleaseArchitecture: BinaryPath])
}

//
//  BinaryOutput.swift
//  nnex
//
//  Created by Nikolai Nobadi on 12/9/25.
//

public enum BinaryOutput {
    case single(BinaryInfo)
    case multiple([ReleaseArchitecture: BinaryInfo])
}

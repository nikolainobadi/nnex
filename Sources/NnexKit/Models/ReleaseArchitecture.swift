//
//  ReleaseArchitecture.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

public enum ReleaseArchitecture {
    case arm, intel
    
    var name: String {
        switch self {
        case .arm:
            return "arm64"
        case .intel:
            return "x86_64"
        }
    }
}

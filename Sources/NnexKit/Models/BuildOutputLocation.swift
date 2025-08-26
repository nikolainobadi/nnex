//
//  BuildOutputLocation.swift
//  NnexKit
//
//  Created by Nikolai Nobadi on 8/26/25.
//

public enum BuildOutputLocation {
    case currentDirectory(BuildType)
    case desktop
    case custom(String)
}
//
//  ReleaseVersionInfo.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

public enum ReleaseVersionInfo: Sendable {
    case version(String)
    case increment(VersionPart)
    
    public enum VersionPart: String, CaseIterable, Sendable {
        case major, minor, patch
        
        public init?(string: String) {
            self.init(rawValue: string.lowercased())
        }
    }
    
    public init?(argument: String) {
        if let versionPart = VersionPart(rawValue: argument) {
            self = .increment(versionPart)
        } else {
            self = .version(argument)
        }
    }
}

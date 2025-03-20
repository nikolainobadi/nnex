//
//  VersionOrIncrement.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/20/25.
//

import ArgumentParser

enum VersionOrIncrement: ExpressibleByArgument {
    case version(String)
    case increment(VersionPart)
    
    enum VersionPart: String, ExpressibleByArgument {
        case major, minor, patch
        
        init?(string: String) {
            self.init(rawValue: string.lowercased())
        }
    }
    
    init?(argument: String) {
        if let versionPart = VersionPart(rawValue: argument) {
            self = .increment(versionPart)
        } else {
            self = .version(argument)
        }
    }
}

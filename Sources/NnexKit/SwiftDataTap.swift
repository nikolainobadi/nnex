//
//  SwiftDataTap.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import SwiftData

@Model
public final class SwiftDataTap {
    @Attribute(.unique) public var name: String
    @Attribute(.unique) public var localPath: String
    @Attribute(.unique) public var remotePath: String
    @Relationship(deleteRule: .cascade, inverse: \SwiftDataFormula.tap) public var formulas: [SwiftDataFormula] = []
    
    public init(name: String, localPath: String, remotePath: String) {
        self.name = name
        self.localPath = localPath
        self.remotePath = remotePath
    }
}



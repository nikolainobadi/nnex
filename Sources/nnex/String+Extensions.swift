//
//  String+Extensions.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

extension String {
    var homebrewTapName: String {
        return "homebrew-\(self)"
    }
    
    var removingHomebrewPrefix: String {
        guard self.hasPrefix("homebrew-") else {
            return self
        }
        
        return String(self.dropFirst("homebrew-".count))
    }
}

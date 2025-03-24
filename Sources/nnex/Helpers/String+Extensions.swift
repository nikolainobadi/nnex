//
//  String+Extensions.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

/// Adds convenience properties for working with Homebrew tap names.
extension String {
    /// Returns a string formatted as a Homebrew tap name.
    var homebrewTapName: String {
        return "homebrew-\(self)"
    }
    
    /// Removes the "homebrew-" prefix from the string, if present.
    var removingHomebrewPrefix: String {
        guard self.hasPrefix("homebrew-") else {
            return self
        }
        
        return String(self.dropFirst("homebrew-".count))
    }
}

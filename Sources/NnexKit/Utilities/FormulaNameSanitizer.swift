//
//  FormulaNameSanitizer.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

import Foundation

/// Utility for sanitizing formula names to ensure they are valid Ruby class names.
public enum FormulaNameSanitizer {
    /// Converts a dash-separated name to PascalCase for valid Ruby class names.
    /// Examples:
    /// - "my-tool" -> "MyTool"
    /// - "awesome-cli-tool" -> "AwesomeCliTool"
    /// - "tool" -> "Tool"
    /// - "my--tool" -> "MyTool" (handles multiple dashes)
    public static func sanitizeFormulaName(_ name: String) -> String {
        // Split by dash and filter out empty components (handles multiple consecutive dashes)
        let components = name.split(separator: "-").map(String.init).filter { !$0.isEmpty }
        
        // If no components after filtering, return capitalized original name as fallback
        guard !components.isEmpty else {
            return name.capitalized
        }
        
        // Convert each component to capitalized and join
        return components.map { $0.capitalized }.joined()
    }
}

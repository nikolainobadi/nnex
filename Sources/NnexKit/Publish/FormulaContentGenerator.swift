//
//  FormulaContentGenerator.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

public enum FormulaContentGenerator {
    public static func makeFormulaFileContent(formula: SwiftDataFormula, assetURL: String, sha256: String) -> String {
        return makeFormulaFileContent(
            name: formula.name,
            details: formula.details,
            homepage: formula.homepage,
            license: formula.license,
            assetURL: assetURL,
            sha256: sha256
        )
    }
    
    public static func makeFormulaFileContent(name: String, details: String, homepage: String, license: String, assetURL: String, sha256: String) -> String {
        return """
        class \(name.capitalized) < Formula
            desc "\(details)"
            homepage "\(homepage)"
            url "\(assetURL)"
            sha256 "\(sha256)"
            license "\(license)"

            def install
              bin.install "\(name)"
            end
          
            test do
              system "#{bin}/\(name)", "--help"
            end
          end

        """
    }
}

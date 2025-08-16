//
//  FormulaContentGenerator.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

/// Generates the content for a Homebrew formula file.
public enum FormulaContentGenerator {
    /// Creates the formula file content using a SwiftDataFormula object.
    /// - Parameters:
    ///   - formula: The SwiftDataFormula object containing formula details.
    ///   - assetURL: The URL of the binary or tarball asset.
    ///   - sha256: The SHA256 hash of the asset.
    /// - Returns: The generated formula file content as a string.
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

    /// Creates the formula file content using individual formula properties.
    /// - Parameters:
    ///   - name: The name of the formula.
    ///   - details: A description of the formula.
    ///   - homepage: The homepage URL of the formula.
    ///   - license: The license under which the formula is distributed.
    ///   - assetURL: The URL of the binary or tarball asset.
    ///   - sha256: The SHA256 hash of the asset.
    /// - Returns: The generated formula file content as a string.
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

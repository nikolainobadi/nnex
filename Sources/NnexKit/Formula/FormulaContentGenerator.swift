//
//  FormulaContentGenerator.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/19/25.
//

public enum FormulaContentGenerator {
    public static func makeFormulaFileContent(
        name: String,
        details: String,
        homepage: String,
        license: String,
        version: String,
        assetURL: String,
        sha256: String
    ) -> String {
        return """
        class \(FormulaNameSanitizer.sanitizeFormulaName(name)) < Formula
            desc "\(details)"
            homepage "\(homepage)"
            url "\(assetURL)"
            sha256 "\(sha256)"
            version "\(version)"
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

    public static func makeFormulaFileContent(
        name: String,
        details: String,
        homepage: String,
        license: String,
        version: String,
        armURL: String?,
        armSHA256: String?,
        intelURL: String?,
        intelSHA256: String?
    ) -> String {
        let hasArm = (armURL?.isEmpty == false) && (armSHA256?.isEmpty == false)
        let hasIntel = (intelURL?.isEmpty == false) && (intelSHA256?.isEmpty == false)

        if hasArm && hasIntel {
            return """
            class \(FormulaNameSanitizer.sanitizeFormulaName(name)) < Formula
                desc "\(details)"
                homepage "\(homepage)"
                version "\(version)"
                license "\(license)"

                on_macos do
                    on_arm do
                        url "\(armURL!)"
                        sha256 "\(armSHA256!)"
                    end

                    on_intel do
                        url "\(intelURL!)"
                        sha256 "\(intelSHA256!)"
                    end
                end

                def install
                    bin.install "\(name)"
                end

                test do
                    system "#{bin}/\(name)", "--help"
                end
            end
            """
        } else if hasArm {
            return makeFormulaFileContent(
                name: name,
                details: details,
                homepage: homepage,
                license: license,
                version: version,
                assetURL: armURL!,
                sha256: armSHA256!
            )
        } else if hasIntel {
            return makeFormulaFileContent(
                name: name,
                details: details,
                homepage: homepage,
                license: license,
                version: version,
                assetURL: intelURL!,
                sha256: intelSHA256!
            )
        } else {
            return makeFormulaFileContent(
                name: name,
                details: details,
                homepage: homepage,
                license: license,
                version: version,
                assetURL: "",
                sha256: ""
            )
        }
    }
}

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
        assetURL: String,
        sha256: String
    ) -> String {
        return """
        class \(name) < Formula
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

    public static func makeFormulaFileContent(
        name: String,
        details: String,
        homepage: String,
        license: String,
        armURL: String?,
        armSHA256: String?,
        intelURL: String?,
        intelSHA256: String?
    ) -> String {
        let hasArm = (armURL?.isEmpty == false) && (armSHA256?.isEmpty == false)
        let hasIntel = (intelURL?.isEmpty == false) && (intelSHA256?.isEmpty == false)

        if hasArm && hasIntel {
            return """
            class \(name) < Formula
                desc "\(details)"
                homepage "\(homepage)"
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
                assetURL: armURL!,
                sha256: armSHA256!
            )
        } else if hasIntel {
            return makeFormulaFileContent(
                name: name,
                details: details,
                homepage: homepage,
                license: license,
                assetURL: intelURL!,
                sha256: intelSHA256!
            )
        } else {
            return makeFormulaFileContent(
                name: name,
                details: details,
                homepage: homepage,
                license: license,
                assetURL: "",
                sha256: ""
            )
        }
    }
}

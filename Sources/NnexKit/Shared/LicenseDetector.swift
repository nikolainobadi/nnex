//
//  LicenseDetector.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

/// Detects the license type from a given directory.
public enum LicenseDetector {
    /// Scans the directory for common license files and attempts to detect the license type.
    /// - Parameter directory: The directory to scan for a license file.
    /// - Returns: A string representing the detected license type, or an empty string if none is found.
    public static func detectLicense(in directory: any Directory) -> String {
        let licenseFiles = ["LICENSE", "LICENSE.md", "COPYING"]

        for fileName in licenseFiles {
            guard directory.containsFile(named: fileName) else { continue }

            if let content = try? directory.readFile(named: fileName) {
                if content.contains("MIT License") {
                    return "MIT"
                } else if content.contains("Apache License") {
                    return "Apache"
                } else if content.contains("GNU General Public License") {
                    return "GPL"
                } else if content.contains("BSD License") {
                    return "BSD"
                }
            }
        }

        return ""
    }
}

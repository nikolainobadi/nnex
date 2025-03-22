//
//  LicenseDetector.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/22/25.
//

import Files

public enum LicenseDetector {
    public static func detectLicense(in folder: Folder) -> String {
        let licenseFiles = ["LICENSE", "LICENSE.md", "COPYING"]
        
        for fileName in licenseFiles {
            if let file = try? folder.file(named: fileName) {
                let content = try? file.readAsString()
                if let content = content {
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
        }
        
        return ""
    }
}

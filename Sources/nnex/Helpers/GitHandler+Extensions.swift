//
//  GitHandler+Extensions.swift
//  nnex
//
//  Created by Nikolai Nobadi on 3/24/25.
//

import NnexKit

extension GitHandler {
    private var homebrewInstallation: String {
        return """
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        """
    }
    
    func checkForGitHubCLI() throws {
        do {
            try ghVerification()
        } catch {
            print("""
            GitHub CLI (\("gh".green) is not installed on your system. Please install it to proceed.
            
            To install using Homebrew:
            1. Make sure Homebrew is installed: \("brew --version".yellow)
            2. If Homebrew is not installed, run:
            
               \(homebrewInstallation.yellow)
            
            3. Install GitHub CLI: \("brew install gh".yellow)
            4. Verify installation: \("gh --version".yellow) 

            Alternatively, install directly using the official script:
            
            \("curl -fsSL https://cli.github.com/install.sh | sudo bash".yellow)

            Once installed, please rerun this command.
            """)
            throw error
        }
    }
}

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.1] - 2025-09-02

### Fixed
- Test hang bug with comprehensive error handling improvements in ProjectBuilder

## [0.9.0] - 2025-08-26

### Added
- Binary archiving with tar.gz compression for releases
- Binary stripping functionality to reduce executable size
- Comprehensive execution manager architecture for build, publish, and create-tap operations
- Executable name resolution service for automatic binary naming
- Binary copy utilities with desktop and custom output location support
- Enhanced SwiftData test isolation with unique stores per test

### Changed
- Major folder reorganization with improved separation between Commands, Core, Domain, and Infrastructure layers
- Build command moved from `BuildExecutable/` to `BuildCommand/` folder structure
- All helper classes reorganized into appropriate domain layers (Handlers, Services, Utilities)
- Consistent manager pattern implementation across all major commands
- Enhanced test architecture with better mock factory support

### Fixed
- Binary uploading to ensure consistent SHA256 between formula and GitHub releases
- GitHub release creation workflow with proper tar.gz asset handling
- Test suite reliability with improved SwiftData context management
- CreateTap command functionality and associated test coverage

### Security  
- Binary stripping removes debug symbols reducing attack surface
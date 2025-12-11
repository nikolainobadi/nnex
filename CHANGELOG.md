# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-12-11

### Fixed
- Version string normalization now consistently handles and removes "v" prefix

## [1.0.0] - 2025-11-20

### Added
- Folder browsing interface for ImportTap command allowing visual selection of Homebrew tap folders
- Folder browsing interface for CreateTap command for selecting tap locations
- File selection option for release notes in publish workflow

### Changed
- Updated to SwiftPickerKit package for improved interactive selection interfaces

## [0.9.7] - 2025-11-08

### Fixed
- Version numbers in formulas now strip "v" prefix for proper Homebrew compliance

## [0.9.6] - 2025-11-08

### Added
- Version field in generated Homebrew formulas

## [0.9.5] - 2025-10-19

### Fixed
- Formula files are now correctly published to Formula subfolder within tap directory
- Remove-formula command now properly deletes formula files from Formula subfolder

## [0.9.4] - 2025-10-18

### Fixed
- Create-tap command now creates Formula subfolder for proper Homebrew tap structure
- Import-tap command handles errors gracefully when brew info cannot access local formulas
- Import-tap command handles taps without Formula folder

## [0.9.3] - 2025-09-19

### Changed
- Updated NnShellKit dependency to version 2.0.0 from preview branch
- Simplified test helper method structure for improved maintainability

## [0.9.2] - 2025-09-10

### Added
- Project changelog documentation

### Fixed
- Formula path update in publish workflow for proper Homebrew integration

## [0.9.1] - 2025-09-02

### Fixed
- Application hang during project building operations

## [0.9.0] - 2025-08-26

### Added
- Binary archiving with tar.gz compression for releases
- Binary stripping functionality to reduce executable size
- Binary copy utilities with desktop and custom output location support

### Fixed
- Binary uploading to ensure consistent SHA256 between formula and GitHub releases
- GitHub release creation workflow with proper tar.gz asset handling
- CreateTap command functionality

### Security
- Binary stripping removes debug symbols reducing attack surface

## [0.8.12] - 2025-08-25

### Added
- Binary stripping functionality to reduce executable size

## [0.8.11] - 2025-08-25

### Fixed
- Binary uploading to ensure consistent SHA256 between formula and GitHub releases

## [0.8.10] - 2025-08-25

### Added
- Binary archiving with tar.gz compression format

## [0.8.9] - 2025-08-25

### Fixed
- GitHub release creation workflow with proper binary uploading

## [0.8.8] - 2025-08-25

### Added
- Support for uploading multiple binaries in single GitHub release

## [0.8.7] - 2025-08-16

### Fixed
- Auto version incrementing bug

## [0.8.6] - 2025-08-16

### Added
- Auto version incrementing with commit and push during publish workflow

## [0.8.5] - 2025-08-11

### Added
- Automatic version incrementing functionality

## [0.8.4] - 2025-08-11

### Added
- Archive command for macOS binary packaging
- Formula name sanitation for proper Homebrew formula generation

## [0.8.3] - 2025-07-13

### Added
- Version command to display current tool version
- Enhanced build command with improved error handling

## [0.8.2] - 2025-04-27

### Fixed
- Formula path synchronization bug during publish workflow

## [0.8.1] - 2025-04-27

### Fixed
- Project folder path consistency issues

## [0.8.0] - 2025-04-21

### Added
- Enhanced build command functionality
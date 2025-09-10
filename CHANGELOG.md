# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
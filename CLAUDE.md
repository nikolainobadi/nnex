# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Building the Project
```bash
swift build -c release
```

### Running Tests
```bash
swift test
```

### Running Individual Tests
```bash
swift test --filter BuildExecutableTests
swift test --filter PublishTests
swift test --filter CreateTapTests
```

### Local Development Testing
Build and test the executable locally:
```bash
swift build -c release
.build/release/nnex --help
```

## Project Architecture

**nnex** is a Swift command-line tool built with Swift Package Manager that streamlines Homebrew distribution of Swift CLI tools. The architecture follows a modular, command-driven design pattern.

### Core Structure

- **Main Entry Point**: `Sources/nnex/Commands/Main/nnex.swift` - The main `@main` struct using Swift ArgumentParser
- **Command Architecture**: Three main command groups:
  - `Brew` - Homebrew and GitHub distribution commands (publish, import-tap, create-tap, etc.)
  - `Build` - Local binary building functionality
  - `Config` - Configuration management

### Key Architectural Patterns

- **Dependency Injection**: Uses `ContextFactory` protocol for creating dependencies (Shell, Picker, GitHandler, NnexContext)
- **Command Pattern**: Each command is a separate `ParsableCommand` struct under the main command namespaces
- **External Dependencies**: Leverages `NnexKit` (custom package) for core business logic, `SwiftPicker` for interactive selections, and `ArgumentParser` for CLI parsing

### Critical Dependencies

The project depends heavily on:
- **NnexKit**: Main business logic package containing core functionality
- **SwiftPicker**: Interactive command-line selection interfaces  
- **ArgumentParser**: CLI parsing and command structure

### Test Architecture

Tests are organized by command functionality:
- Mock factories and shared test utilities in `Tests/nnexTests/Shared/`
- Command-specific test suites matching the source structure
- Uses `NnexSharedTestHelpers` from NnexKit for shared testing utilities

### Build Types

The tool supports multiple build configurations:
- `universal` - Multi-architecture binary (ARM64 + x86_64)
- `release` - Optimized release build
- `debug` - Debug build with symbols

### Platform Requirements

- macOS 14+ minimum deployment target
- Swift 6.0+ required
- Requires Homebrew and GitHub CLI (`gh`) for full functionality
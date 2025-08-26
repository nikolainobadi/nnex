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

**nnex** is a Swift command-line tool built with Swift Package Manager that streamlines Homebrew distribution of Swift CLI tools. The architecture follows a modular, command-driven design pattern with clear separation of concerns.

### Core Structure

- **Main Entry Point**: `Sources/nnex/Commands/Main/nnex.swift` - The main `@main` struct using Swift ArgumentParser
- **Command Architecture**: Four main command groups:
  - `Brew` - Homebrew and GitHub distribution commands (publish, import-tap, create-tap, etc.)
  - `Build` - Local binary building functionality  
  - `Config` - Configuration management
  - `Archive` - Archiving and packaging functionality

### Improved Folder Organization (as of August 2024)

```
Sources/nnex/
├── Commands/               # Command implementations
│   ├── Main/              # Entry point
│   ├── Archive/           # Archive command group
│   ├── Brew/              # Brew command group  
│   ├── Build/             # Build command group
│   ├── Config/            # Config command group
│   └── Export/            # Export command group
├── Core/                  # Core application components
│   ├── Context/           # Context factory and dependency injection
│   └── Extensions/        # Application-level extensions
├── Domain/                # Business logic
│   ├── Execution/         # Execution managers (BuildExecutionManager, PublishExecutionManager, CreateTapManager)
│   ├── Handlers/          # Various handlers (ReleaseHandler, ReleaseNotesHandler, etc.)
│   └── Services/          # Domain services (PublishInfoLoader, ExecutableNameResolver)
└── Infrastructure/        # External concerns
    ├── Picker/           # Interactive selection implementations
    └── (Various provider implementations)
```

### Key Architectural Patterns

- **Manager Pattern**: Commands delegate to execution managers (e.g., `CreateTapManager`, `PublishExecutionManager`) for business logic
- **Dependency Injection**: Uses `ContextFactory` protocol for creating dependencies (Shell, Picker, GitHandler, NnexContext)
- **Command Pattern**: Each command is a separate `ParsableCommand` struct under the main command namespaces
- **Internal Libraries**: Contains `NnexKit` as an internal library providing core business logic
- **External Dependencies**: Uses `SwiftPicker` for interactive selections and `ArgumentParser` for CLI parsing

### Critical Dependencies

The project depends on:
- **NnexKit**: Internal library (`Sources/NnexKit/`) containing core functionality
- **NnexSharedTestHelpers**: Internal test helpers library for shared testing utilities
- **SwiftPicker**: Interactive command-line selection interfaces (external package)
- **ArgumentParser**: CLI parsing and command structure (external package)
- **SwiftData**: For persistent storage of tap and formula information
- **Files**: File system operations (external package)
- **GitShellKit**: Git operations wrapper (external package)

### Test Architecture

Tests are organized to mirror the source structure:
- Mock factories and shared test utilities in `Tests/nnexTests/Shared/`
- Command-specific test suites in `Tests/nnexTests/Commands/`
- Domain logic tests in `Tests/nnexTests/Domain/` matching source organization
- Uses `NnexSharedTestHelpers` library for shared testing utilities
- Tests follow `@MainActor` pattern for SwiftData compatibility
- Comprehensive unit tests for all execution managers

### Build Types

The tool supports multiple build configurations:
- `universal` - Multi-architecture binary (ARM64 + x86_64)
- `release` - Optimized release build
- `debug` - Debug build with symbols

### Platform Requirements

- macOS 14+ minimum deployment target
- Swift 6.0+ required
- Requires Homebrew and GitHub CLI (`gh`) for full functionality

## Recent Improvements (August 2024)

### Architecture Refactoring
- **Improved folder organization**: Clear separation between Commands, Core, Domain, and Infrastructure layers
- **Manager pattern implementation**: Commands now delegate to execution managers for better testability
- **Consistent patterns**: All commands follow the same structure with dependency injection

### Key Changes
- `CreateTap` command refactored to use `CreateTapManager` following the pattern of other commands
- Test infrastructure improved with `@MainActor` pattern for SwiftData compatibility
- Fixed test environment issues with proper mock factory parameter passing
- All execution managers now have comprehensive unit test coverage

### Known Issues
- SwiftData may show "Unable to determine Bundle Name" errors at the end of test runs in Xcode (tests still execute successfully)
- This is a known issue with SwiftData in test environments and doesn't affect functionality

## Code Style Preferences

### Extension Organization
- **Private Extensions**: Use `private extension` for helper methods instead of mixing public/private methods in the same extension
- **Clear Separation**: Add blank lines before MARK comments for visual separation
- **Structure Pattern**: Main implementation → blank line → `// MARK: - Private Methods` → `private extension`

### Method Formatting
- **Single-Line Signatures**: Keep method signatures on single lines when they fit reasonably (avoid unnecessary line breaks)
- **Parameter Lists**: Only break parameter lists across multiple lines when they become too long for readability

### File Organization
- **MARK Comments**: Use consistent style `// MARK: - Section Name`
- **Extension Sectioning**: Group related functionality with appropriate MARK comments
- **Protocol Conformances**: Keep protocol conformances (like `ExpressibleByArgument`) in separate extensions at the end of files
- **Consistency**: Follow established patterns from existing files like `BuildExecutable.swift`

### Example Structure
```swift
extension Nnex.CommandName {
    // Main command implementation
    func run() throws {
        // implementation
    }
}


// MARK: - Private Methods  
private extension Nnex.CommandName {
    func helperMethod() throws -> String {
        // helper implementation
    }
}

// MARK: - ArgumentParser Conformance
extension SomeEnum: ExpressibleByArgument {
    // protocol conformance
}
```
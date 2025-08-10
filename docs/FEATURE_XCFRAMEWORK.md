# XCFramework Command Feature Specification

## Overview

### Purpose
Add a new `xcframework` command to nnex that provides controlled XCFramework building with enhanced user experience, smart defaults, and flexible configuration options. This replaces the basic `buildxc()` zsh function with a more robust, integrated solution.

### Goals
- **Zero configuration** for common use cases with smart defaults
- **Full interactivity** when customization is needed
- **Dry-run capability** for learning and scripting
- **Consistent UX** with existing nnex commands
- **Enhanced control** over platforms, architectures, and output

## Command Interface

### Base Command
```bash
nnex xcframework [OPTIONS]
```

### Execution Modes

#### 1. Default Mode (Smart Defaults)
```bash
nnex xcframework
```
- Uses all smart defaults
- Minimal user interaction
- Builds universal XCFramework for iOS to Desktop

#### 2. Interactive Mode
```bash
nnex xcframework --interactive
nnex xcframework -i
```
- Prompts for every configurable option
- Full control over all parameters
- Guided experience with validation

#### 3. Dry-Run Mode
```bash
nnex xcframework --dry-run                    # Print + copy to clipboard
nnex xcframework --dry-run --no-clipboard     # Print only
```
- Generates and displays xcodebuild commands
- No actual building performed
- Educational and scripting tool

### Command Options

#### Configuration Options
```bash
--path, -p <PATH>              # Project directory (default: current directory)
--output, -o <PATH>            # Output location (default: Desktop)
--name <NAME>                  # Framework name override (default: auto-detect)
--scheme <SCHEME>              # Xcode scheme (default: auto-detect or prompt)
--platforms <LIST>             # Comma-separated platforms (default: ios)
--architectures <TYPE>         # Architecture strategy (default: universal)
```

#### Build Options
```bash
--no-clean                     # Skip cleaning build directory
--no-distribution              # Disable BUILD_LIBRARY_FOR_DISTRIBUTION
--verbose                      # Show detailed xcodebuild output
--open-finder                  # Open result in Finder after build
```

#### Mode Control
```bash
--interactive, -i              # Enable interactive mode
--dry-run                      # Generate commands without executing
--no-clipboard                 # Don't copy dry-run output to clipboard
```

## Smart Defaults

### Platform Defaults
- **Default Platform**: iOS only (Device + Simulator)
- **Architecture Strategy**: Universal (ARM64 + x86_64)
- **Auto-detection**: Scan project for available platforms

### Output Defaults
- **Location**: Desktop (`~/Desktop/`)
- **Naming**: `{FrameworkName}.xcframework`
- **Framework Name**: Auto-detect from current directory name

### Build Defaults
- **Clean Build**: Enabled (clean build directory before building)
- **Distribution**: `BUILD_LIBRARY_FOR_DISTRIBUTION=YES`
- **Skip Install**: `SKIP_INSTALL=NO`
- **Scheme**: Auto-detect single scheme or prompt if multiple

### Detection Logic
1. **Framework Name**: Use current directory basename
2. **Scheme Detection**: Parse `.xcodeproj` or `.xcworkspace` for schemes
3. **Platform Availability**: Check project settings for supported platforms
4. **Project Type**: Validate Xcode project exists and contains framework targets

## Interactive Mode Specification

### Flow Sequence
1. **Project Validation**
   - Verify Xcode project/workspace exists
   - Validate framework targets are available
   - Display detected project information

2. **Platform Selection**
   ```
   Select target platforms (multi-select):
   ☐ iOS (Device + Simulator)
   ☐ macOS
   ☐ macOS Catalyst  
   ☐ tvOS (Device + Simulator)
   ☐ watchOS (Device + Simulator)
   ☐ visionOS (Device + Simulator)
   ```

3. **Architecture Strategy**
   ```
   Select architecture strategy:
   1. Universal (ARM64 + x86_64) - Recommended
   2. ARM64 only (Apple Silicon native)
   3. x86_64 only (Intel native)
   4. Custom per-platform selection...
   ```

4. **Scheme Selection** (if multiple detected)
   ```
   Select Xcode scheme:
   1. MyFramework
   2. MyFrameworkDemo
   3. MyFrameworkTests
   ```

5. **Output Configuration**
   ```
   Where should the XCFramework be created?
   1. Desktop (~Desktop/MyFramework.xcframework)
   2. Current directory (./MyFramework.xcframework)
   3. Custom location...
   ```

6. **Build Options**
   ```
   Build configuration:
   ☑ Clean build directory before building
   ☑ Enable BUILD_LIBRARY_FOR_DISTRIBUTION
   ☐ Show verbose xcodebuild output
   ☐ Open in Finder when complete
   ```

7. **Confirmation**
   ```
   Configuration Summary:
   - Framework: MyFramework
   - Platforms: iOS (Device + Simulator)
   - Architecture: Universal
   - Output: ~/Desktop/MyFramework.xcframework
   - Clean: Yes, Distribution: Yes
   
   Proceed with build? [Y/n]
   ```

### Validation Rules
- At least one platform must be selected
- Custom output paths must be valid and writable
- Scheme must exist in the project
- Framework name must be valid identifier

## Dry-Run Mode Specification

### Output Format
```bash
# XCFramework Build Commands
# Framework: MyFramework
# Platforms: iOS (Device + Simulator)
# Architecture: Universal
# Output: ~/Desktop/MyFramework.xcframework

# Clean previous builds
rm -rf ./build
rm -rf ~/Desktop/MyFramework.xcframework

# Build iOS Device Archive (ARM64)
xcodebuild archive \
  -scheme "MyFramework" \
  -destination "generic/platform=iOS" \
  -archivePath "./build/MyFramework_iOSDevices.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build iOS Simulator Archive (ARM64 + x86_64)
xcodebuild archive \
  -scheme "MyFramework" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "./build/MyFramework_iOSSimulators.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Create XCFramework
xcodebuild -create-xcframework \
  -framework "./build/MyFramework_iOSDevices.xcarchive/Products/Library/Frameworks/MyFramework.framework" \
  -framework "./build/MyFramework_iOSSimulators.xcarchive/Products/Library/Frameworks/MyFramework.framework" \
  -output "~/Desktop/MyFramework.xcframework"

# Optional: Open in Finder
# open -R "~/Desktop/MyFramework.xcframework"
```

### Clipboard Integration
- **Default**: Copy commands to clipboard using `pbcopy`
- **Opt-out**: Use `--no-clipboard` to only print
- **Feedback**: Display "Commands copied to clipboard" message

## Implementation Architecture

### File Structure
```
Sources/nnex/Commands/XCFramework/
├── XCFramework.swift              # Main command implementation
├── XCFrameworkBuilder.swift       # Build execution logic
├── Platform.swift                 # Platform enumeration and logic
├── ArchitectureStrategy.swift     # Architecture handling
└── XCFrameworkConfig.swift        # Configuration data structure
```

### Integration Points

#### Main Command Registration
```swift
// In Sources/nnex/Commands/Main/nnex.swift
static let configuration = CommandConfiguration(
    abstract: "...",
    version: "0.8.3",
    subcommands: [Brew.self, Build.self, Config.self, XCFramework.self]
)
```

#### Dependency Usage
- **Shell**: Use `Nnex.makeShell()` for command execution
- **Picker**: Use `Nnex.makePicker()` for interactive selections
- **Context**: Use `Nnex.makeContext()` for configuration
- **Files**: Follow existing patterns from `BuildExecutable.swift`

#### Output Location Pattern
```swift
enum XCFrameworkOutputLocation {
    case currentDirectory
    case desktop
    case custom(String)
}

extension XCFrameworkOutputLocation: DisplayablePickerItem {
    var displayName: String {
        switch self {
        case .currentDirectory:
            return "Current directory"
        case .desktop:
            return "Desktop"
        case .custom:
            return "Custom location..."
        }
    }
}
```

### Data Structures

#### Platform Enumeration
```swift
enum XCFrameworkPlatform: String, CaseIterable {
    case iOS = "ios"
    case macOS = "macos" 
    case macOSCatalyst = "maccatalyst"
    case tvOS = "tvos"
    case watchOS = "watchos"
    case visionOS = "visionos"
    
    var destinations: [String] {
        switch self {
        case .iOS:
            return ["generic/platform=iOS", "generic/platform=iOS Simulator"]
        case .macOS:
            return ["generic/platform=macOS"]
        case .macOSCatalyst:
            return ["generic/platform=macOS,variant=Mac Catalyst"]
        // ... other cases
        }
    }
}
```

#### Architecture Strategy
```swift
enum ArchitectureStrategy: String, CaseIterable {
    case universal
    case arm64Only = "arm64"
    case x86_64Only = "x86_64"
    case custom
    
    var buildSettings: [String: String] {
        switch self {
        case .universal:
            return ["ARCHS": "arm64 x86_64"]
        case .arm64Only:
            return ["ARCHS": "arm64"]
        case .x86_64Only:
            return ["ARCHS": "x86_64"]
        case .custom:
            return [:] // Will be configured interactively
        }
    }
}
```

#### Configuration Structure
```swift
struct XCFrameworkConfig {
    let frameworkName: String
    let scheme: String
    let projectPath: String
    let platforms: [XCFrameworkPlatform]
    let architectureStrategy: ArchitectureStrategy
    let outputLocation: XCFrameworkOutputLocation
    let cleanBuild: Bool
    let enableDistribution: Bool
    let verbose: Bool
    let openInFinder: Bool
}
```

## Technical Requirements

### Project Detection Logic
1. **Xcode Project Search**:
   - Look for `*.xcodeproj` in specified path
   - Look for `*.xcworkspace` in specified path
   - Prefer workspace over project if both exist

2. **Scheme Detection**:
   ```swift
   func detectSchemes(projectPath: String) throws -> [String] {
       // Parse .xcschememanagement.plist or use xcodebuild -list
   }
   ```

3. **Framework Validation**:
   - Verify project contains framework targets
   - Check that selected scheme builds a framework
   - Validate framework name matches expected output

### Command Generation Logic
```swift
struct XCodeBuildCommand {
    let action: String // "archive" or "create-xcframework"
    let scheme: String?
    let destination: String?
    let archivePath: String?
    let buildSettings: [String: String]
    let additionalArgs: [String]
    
    var commandString: String {
        // Generate full xcodebuild command
    }
}
```

### Error Handling Strategy
- **Project Not Found**: Clear error message with suggestions
- **No Framework Targets**: Guide user to check project configuration  
- **Build Failures**: Parse and display relevant xcodebuild errors
- **Permission Issues**: Handle read/write permission problems
- **Invalid Paths**: Validate all file paths before execution

### Progress Feedback
```swift
protocol XCFrameworkProgressDelegate {
    func didStartPhase(_ phase: BuildPhase)
    func didCompletePhase(_ phase: BuildPhase)
    func didFailPhase(_ phase: BuildPhase, error: Error)
}

enum BuildPhase {
    case cleaning
    case archiving(platform: XCFrameworkPlatform)
    case creatingXCFramework
    case copyingToDestination
}
```

## Testing Strategy

### Unit Tests Structure
```
Tests/nnexTests/XCFramework/
├── XCFrameworkCommandTests.swift       # Command parsing and validation
├── XCFrameworkBuilderTests.swift       # Build logic tests
├── PlatformDetectionTests.swift        # Project analysis tests
├── ConfigurationTests.swift            # Configuration validation
└── MockFactories/
    ├── MockXCFrameworkShell.swift      # Shell command mocking
    └── MockXCFrameworkPicker.swift     # User interaction mocking
```

### Test Scenarios

#### Command Parsing Tests
- Valid flag combinations
- Invalid flag combinations
- Default value application
- Interactive mode activation

#### Build Logic Tests  
- Command generation for different platforms
- Architecture strategy application
- Output location handling
- Clean vs. non-clean builds

#### Integration Tests
- Full workflow with mocked dependencies
- Error handling scenarios
- Progress reporting
- File system interactions

#### Mock Factory Patterns
```swift
class MockXCFrameworkContextFactory: ContextFactory {
    func makeShell() -> Shell {
        return MockXCFrameworkShell(
            expectedCommands: [...],
            responses: [...]
        )
    }
    
    func makePicker() -> Picker {
        return MockXCFrameworkPicker(
            presetSelections: [...]
        )
    }
}
```

## Usage Examples

### Common Use Cases

#### 1. Quick iOS XCFramework (Default)
```bash
cd MyFrameworkProject
nnex xcframework
```
**Result**: Creates universal iOS XCFramework on Desktop

#### 2. Interactive Configuration
```bash
nnex xcframework --interactive
```
**Result**: Guided setup for all options

#### 3. Multi-Platform Build
```bash
nnex xcframework --platforms ios,macos --output ./dist
```
**Result**: iOS and macOS XCFramework in ./dist directory

#### 4. Learning/Scripting (Dry-Run)
```bash
nnex xcframework --platforms ios,macos --dry-run
```
**Result**: Prints commands to console and copies to clipboard

#### 5. Custom Architecture
```bash
nnex xcframework --architectures arm64 --platforms ios,macos
```
**Result**: ARM64-only build for specified platforms

#### 6. Full Control
```bash
nnex xcframework \
  --path ./MyProject \
  --name MyCustomFramework \
  --scheme MyScheme \
  --platforms ios,macos,tvos \
  --architectures universal \
  --output ~/Documents/Frameworks \
  --verbose \
  --open-finder
```

### Expected Outputs

#### Default Mode Success
```
🔍 Detected framework: MyFramework
📋 Using scheme: MyFramework  
🏗️  Building for iOS (Universal)
📦 Output: ~/Desktop/MyFramework.xcframework

✅ Building iOS Device archive...
✅ Building iOS Simulator archive...  
✅ Creating XCFramework...
🎉 XCFramework created successfully!

   Location: /Users/username/Desktop/MyFramework.xcframework
   Size: 2.4 MB
   Platforms: iOS (Device + Simulator)
```

#### Dry-Run Mode Output
```
# XCFramework build commands will be copied to clipboard
# Run these commands manually to build MyFramework.xcframework

[Generated commands as shown in Dry-Run specification above]

📋 Commands copied to clipboard
💡 Run 'pbpaste | sh' to execute these commands
```

#### Error Handling Examples
```
❌ Error: No Xcode project found in current directory
   💡 Navigate to your Xcode project directory or use --path option

❌ Error: Multiple schemes detected, please specify:
   Available schemes: MyFramework, MyFrameworkDemo, MyFrameworkTests
   💡 Use --scheme option or --interactive mode

❌ Error: Build failed for iOS Device archive
   xcodebuild: error: Scheme "MyFramework" is not configured for archiving
   💡 Check your scheme's Archive configuration in Xcode
```

## Implementation Checklist

### Phase 1: Core Structure
- [ ] Create XCFramework command files and directory structure
- [ ] Implement basic command parsing with ArgumentParser
- [ ] Add platform and architecture enumerations
- [ ] Integrate with main nnex command configuration

### Phase 2: Smart Defaults
- [ ] Implement project detection and validation logic
- [ ] Add scheme auto-detection functionality
- [ ] Create framework name inference from directory
- [ ] Implement default platform and architecture selection

### Phase 3: Interactive Mode
- [ ] Build platform selection interface using SwiftPicker
- [ ] Add architecture strategy selection prompts
- [ ] Implement output location selection (reuse from BuildExecutable)
- [ ] Create build options configuration interface
- [ ] Add confirmation and summary display

### Phase 4: Build Engine
- [ ] Implement XCodeBuildCommand generation logic  
- [ ] Create build execution with progress feedback
- [ ] Add proper error handling and validation
- [ ] Implement file system operations (clean, copy, validate)

### Phase 5: Dry-Run Mode
- [ ] Build command string generation and formatting
- [ ] Implement clipboard integration with pbcopy
- [ ] Add --no-clipboard option support
- [ ] Create formatted output with comments and sections

### Phase 6: Testing & Polish
- [ ] Write comprehensive unit tests for all components
- [ ] Add integration tests with mock factories
- [ ] Test error scenarios and edge cases
- [ ] Add progress indicators and user feedback
- [ ] Update documentation and help text

### Phase 7: Integration
- [ ] Update main command configuration
- [ ] Verify compatibility with existing nnex patterns
- [ ] Test with real Xcode projects
- [ ] Add to CI/CD test suite

## Future Enhancements

### Potential Additions
- **Swift Package Manager Integration**: Support for SPM-based frameworks
- **Custom Build Settings**: Allow arbitrary xcodebuild flags
- **Build Configuration Selection**: Debug vs Release builds
- **Dependency Validation**: Check framework dependencies
- **Size Optimization**: Options for reducing XCFramework size
- **Bitcode Support**: Legacy bitcode embedding options
- **Code Signing**: Automatic code signing configuration

### Advanced Features
- **Batch Processing**: Build multiple frameworks in sequence
- **Template Support**: Save and reuse build configurations
- **CI/CD Integration**: Generate GitHub Actions workflows
- **Distribution**: Integration with package managers and distribution services

This specification provides a complete blueprint for implementing the XCFramework command with all necessary details for development, testing, and integration.
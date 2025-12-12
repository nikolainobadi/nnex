Repository Guidelines
=====================

## Project Structure & Module Organization
- Swift package rooted at `Package.swift`; production code lives under `Sources/` with the main CLI in `Sources/nnex` and shared libraries in `Sources/NnexKit` plus helpers in `Sources/NnexSharedTestHelpers`.
- Tests use Swift Testing and sit in `Tests/` (e.g., `Tests/nnexTests` for CLI-level coverage and `Tests/NnexKitTests` for kit-level logic). Keep new tests parallel to their source modules.
- Shared assets and resources reside in `Resources/`; docs in `docs/`.

## Build, Test, and Development Commands
- `swift build` — compile the package.
- `swift test` — run the Swift Testing suites. Use `swift test --enable-code-coverage` when you need coverage locally.
- `swift package resolve` — ensure dependencies are fetched before building.
- Keep commands non-destructive and reproducible; favor `set -e` in scripts.

## Coding Style & Naming Conventions
- Swift: 4-space indentation, `CamelCase` types, `lowerCamelCase` members. Keep parameter lists on one line when concise.
- File headers in Swift should attribute authorship to Nikolai Nobadi.
- Prefer modular, composable types; separate concerns between controllers (user interaction) and managers/services (business logic).
- Avoid embedding print/logging in lower-level managers; surface messages via controllers.

## Testing Guidelines
- Framework: Swift Testing with `#expect`/`#require`. Use `NnexSharedTestHelpers` (e.g., `MockDirectory`, `MockGitHandler`) and `NnShellTesting.MockShell` for deterministic behavior.
- Name test files after the type under test; keep method names descriptive (e.g., `"Creates tap folder"` labels).
- Cover both success and failure paths; include warning/error propagation in assertions when applicable.
- Do not rely on real network or shell side effects; mock via provided test helpers.

## Commit & Pull Request Guidelines
- Follow existing history: short, imperative commit messages (e.g., `add tap import warnings`, `refactor formula decoder`).
- PRs should state intent, summarize behavior changes, and note testing performed (or explicitly omitted per policy). Link related issues when available and call out any user-facing changes.

## Security & Configuration Tips
- Git/GitHub interactions are mediated via `GitHandler`; ensure GitHub CLI availability is verified before creating repos.
- Scripts should be idempotent and avoid destructive defaults; when writing new scripts, emit colored INFO/SUCCESS/WARNING/ERROR messages and source shared utilities when present.

## Resource Requests
- Ask before reading `~/.codex/guidelines/shared/shared-formatting-codex.md` when working on Swift code.
- Ask before reading `~/.codex/guidelines/testing/base_unit_testing_guidelines.md` when discussing or editing tests.
- Ask before reading `~/.codex/guidelines/testing/CLI_TESTING_GUIDE_CODEX.md` when discussing or editing CLI tests.
- Ask before reading `~/.codex/guidelines/cli/NnShellKit-Usage.md` when shell execution helpers are involved.
- Ask before reading `~/.codex/guidelines/cli/NnShellTesting-Usage.md` when working on shell-related tests.
- Ask before reading `~/.codex/guidelines/cli/SwiftPickerKit-usage.md` when touching SwiftPickerKit flows.
- Ask before reading `~/.codex/guidelines/cli/SwiftPickerTesting-usage.md` when testing SwiftPickerKit flows.

## CLI Design
- Single-responsibility commands
- Clear, predictable argument handling
- Minimal logging to stdout/stderr
- Use `NnShellKit` for shell execution; prefer absolute program paths

## CLI Testing
- Behavior-driven tests for command logic
- Use `makeSUT` pattern where applicable
- Test both success and error paths
- Verify output formatting
- Use `MockShell` from NnShellTesting for shell interactions

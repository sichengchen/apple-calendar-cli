# Repository Guidelines

## Project Structure & Module Organization

This Swift 6 package targets macOS 14+ and uses ArgumentParser and EventKit. `Sources/apple-calendar-cli/AppleCalendarCLI.swift` registers subcommands and global options. Keep CLI parsing in `Commands/`, Calendar access and skill installation in `Services/`, output representations in `Models/`, and shared helpers in `Utilities/`.

XCTest files live in `Tests/apple-calendar-cli-tests/`. The bundled agent reference is `skills/apple-calendar-cli/SKILL.md`. `Info.plist` supplies embedded Calendar permission metadata; `scripts/` and `.github/workflows/` handle verification and releases.

## Build, Test, and Development Commands

- `make build`: build the debug executable with SwiftPM.
- `swift run apple-calendar-cli --help`: run locally and inspect available commands.
- `swift test`: run the XCTest suite.
- `swift test --filter DateParserTests`: run a focused test class.
- `make release`: build an optimized executable and apply its local code signature.
- `bash scripts/verify-permissions.sh .build/release/apple-calendar-cli`: verify embedded permission metadata and signing identity.
- `make install PREFIX="$HOME/.local"`: build and install into a custom prefix.
- `swiftlint lint`: check style when SwiftLint is installed.

## Coding Style & Naming Conventions

Use four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` properties and functions. Match filenames to their primary type, such as `CreateEventCommand.swift`. Use kebab-case CLI names and flags, such as `create-event` and `--all-day`.

Follow `.swiftlint.yml`: line lengths warn at 120 characters and fail at 150; trailing commas are allowed. Preserve existing JSON field names and date/time behavior. Update README usage and the bundled skill when command behavior changes.

## Testing Guidelines

Name test files `<Type>Tests.swift` and test methods `test<Behavior>`. Cover invalid inputs, timezone behavior, and filesystem edge cases when relevant. Use temporary directories for installer tests and remove them during teardown. No numeric coverage threshold is configured. Before submitting code changes, run the tests, release build, and permission verification used by CI.

## Commit & Pull Request Guidelines

Use Conventional Commits, matching history: `feat:`, `fix:`, `docs:`, or `ci:`. Commit coherent units separately and include this trailer:

```text
Co-Authored-By: Sicheng Chen (bot) <gh-bot@scchan.com>
```

PRs should explain the behavior change, link relevant issues, and list verification results. Include CLI output examples for user-visible changes.

## Agent & Configuration Guidelines

Keep temporary plans, handoffs, and session notes outside the repository. Preserve unrelated working-tree changes. Manual Calendar checks require permission; use a disposable calendar for mutation tests. Retain the identifier `com.scchan.apple-calendar-cli` and keep release credentials out of source control.

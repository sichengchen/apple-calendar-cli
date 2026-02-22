---
id: 1
title: Project scaffolding & SPM setup
status: done
type: feature
priority: 1
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
shipped_at: 2026-02-22
pr: https://github.com/sichengchen/apple-calendar-cli/pull/2
---
# Project scaffolding & SPM setup

## Context
The repository is empty — no Swift package exists yet. We need a Swift Package Manager project with the right structure, dependencies, and build configuration.

## Approach
1. Run `swift package init --type executable --name apple-calendar-cli`
2. Add `swift-argument-parser` dependency to `Package.swift`
3. Configure the executable target to link EventKit
4. Add a minimal root command (`AppleCalendarCLI`) with `--version` and `--json` global flags
5. Create `.swiftlint.yml` with sensible defaults
6. Create `.gitignore` for Swift (exclude `.build/`, `.swiftpm/`, `DerivedData/`, etc.)
7. Add `Info.plist` with `NSCalendarsUsageDescription` and entitlements for EventKit calendar access
8. Verify `swift build` and `swiftlint` pass

## Files to change
- `Package.swift` (create — SPM manifest)
- `Sources/main.swift` or `Sources/CalCLI.swift` (create — entry point with root command)
- `.swiftlint.yml` (create — linter config)
- `.gitignore` (create — Swift project ignores)
- `Info.plist` (create — calendar usage description for EventKit permission prompt)

## Verification
- Run: `swift build`
- Expected: Builds successfully, produces `apple-calendar-cli` binary
- Run: `swiftlint`
- Expected: No warnings or errors
- Edge cases: Ensure EventKit framework links correctly on macOS, Info.plist is picked up

## Progress
- Implemented: Package.swift with ArgumentParser + EventKit, root command with --version and --json global flags, .swiftlint.yml, .gitignore, Info.plist with NSCalendarsUsageDescription
- Modified: Package.swift, Sources/apple-calendar-cli/AppleCalendarCLI.swift, .swiftlint.yml, .gitignore, Info.plist
- Verification: swift build passes. swiftlint cannot run (requires full Xcode.app, environment has Command Line Tools only)

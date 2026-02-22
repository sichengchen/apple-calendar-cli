# Apple Calendar CLI — Constitution

## What This Is
A Swift command-line tool that performs CRUD operations on Apple Calendar (Calendar.app) events using EventKit. Designed for both direct human use in the terminal and as a tool for AI agents (via a Claude agent skill). macOS only.

## What This Is NOT
- Not a GUI application — terminal only
- Not cross-platform — macOS only, no iOS/iPadOS/Linux support
- Not a calendar sync service — operates on the local Calendar store via EventKit
- Not a replacement for Calendar.app — a complementary CLI interface

## Technical Decisions
- **Stack**: Swift, Swift Package Manager, EventKit framework
- **Architecture**: CLI with subcommands (list-calendars, list-events, create-event, update-event, delete-event). JSON output mode for machine consumption.
- **Key dependencies**: EventKit (Apple framework for calendar access), ArgumentParser (Swift CLI parsing), Foundation (date handling)

## Testing Strategy
- **What gets tested**: Unit tests for date parsing, event mapping, and output formatting. Integration tests for EventKit operations. E2E tests for full CLI invocations.
- **Tooling**: XCTest via Swift Package Manager, SwiftLint for linting
- **Commands**: `swift test` (tests), `swiftlint` (lint), `swift build` (typecheck/build)

## Principles
1. **JSON-first output** — All commands support `--json` for machine-readable output. AI agents are first-class consumers.
2. **Fail loudly** — Clear error messages with actionable guidance (e.g., "Calendar access denied. Grant access in System Settings > Privacy > Calendars.").
3. **Minimal surface area** — Ship the smallest useful API. Avoid feature creep beyond what's explicitly planned.
4. **Idempotent where possible** — Operations should be safe to retry. Deletes by ID, updates by ID.
5. **Fast startup** — CLI tools must launch instantly. Avoid unnecessary framework imports or lazy-loading overhead.

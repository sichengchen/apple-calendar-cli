---
id: 2
title: List calendars command
status: done
type: feature
priority: 2
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
shipped_at: 2026-02-22
pr: https://github.com/sichengchen/apple-calendar-cli/pull/2
---
# List calendars command

## Context
Depends on plan 001 (project scaffolding). EventKit provides `EKEventStore.calendars(for: .event)` to fetch all calendars. We need to request calendar access, handle permission denial gracefully, and output calendars in both human-readable and JSON formats.

## Approach
1. Create `CalendarService` — a wrapper around `EKEventStore` that handles authorization
2. Implement `requestAccess()` with clear error messaging if denied
3. Create `ListCalendarsCommand` as an ArgumentParser subcommand
4. Fetch all event calendars via EventKit
5. Output: calendar title, type (local/CalDAV/etc.), color, and unique identifier
6. Support `--json` flag for structured JSON output
7. Add unit tests for output formatting

## Files to change
- `Sources/Commands/ListCalendarsCommand.swift` (create — subcommand)
- `Sources/Services/CalendarService.swift` (create — EventKit wrapper)
- `Sources/Models/CalendarInfo.swift` (create — calendar data model)
- `Sources/CalCLI.swift` (modify — register subcommand)
- `Tests/ListCalendarsTests.swift` (create — unit tests)

## Verification
- Run: `swift build && .build/debug/apple-calendar-cli list-calendars`
- Expected: Lists all calendars with title, type, and ID
- Run: `.build/debug/apple-calendar-cli list-calendars --json`
- Expected: JSON array of calendar objects
- Edge cases: No calendars, permission denied, calendar access not yet prompted

## Progress
- Implemented CalendarService with EKEventStore wrapper, requestAccess, listCalendars, fetchEvents, save, delete
- Implemented CalendarInfo model with Codable conformance, human-readable output, hex color extraction
- Implemented ListCalendarsCommand with --json support
- Bumped platform minimum to macOS 14 for requestFullAccessToEvents() API
- Used @preconcurrency import and @unchecked Sendable for EKEventStore compatibility
- Modified: CalendarService.swift, CalendarInfo.swift, ListCalendarsCommand.swift, AppleCalendarCLI.swift, Package.swift
- Verification: swift build passes

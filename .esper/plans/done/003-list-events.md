---
id: 3
title: List events command
status: done
type: feature
priority: 3
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
shipped_at: 2026-02-22
---
# List events command

## Context
Depends on plan 002 (CalendarService exists). EventKit provides `EKEventStore.events(matching:)` with an `NSPredicate` for date range queries. Need to support filtering by date range and optionally by calendar.

## Approach
1. Create `ListEventsCommand` subcommand with options: `--from`, `--to`, `--calendar` (optional filter), `--json`
2. Parse date strings (ISO 8601 format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`)
3. Default `--from` to today, `--to` to 7 days from now if not specified
4. Query EventKit with date predicate
5. Output: event title, start/end times, calendar name, location, event ID
6. Human-readable table format by default, JSON with `--json`
7. Add unit tests for date parsing and output formatting

## Files to change
- `Sources/Commands/ListEventsCommand.swift` (create — subcommand)
- `Sources/Models/EventInfo.swift` (create — event data model)
- `Sources/Utilities/DateParser.swift` (create — date string parsing)
- `Sources/CalCLI.swift` (modify — register subcommand)
- `Tests/ListEventsTests.swift` (create — unit tests)
- `Tests/DateParserTests.swift` (create — date parsing tests)

## Verification
- Run: `.build/debug/apple-calendar-cli list-events`
- Expected: Lists events for the next 7 days
- Run: `.build/debug/apple-calendar-cli list-events --from 2026-02-21 --to 2026-02-28 --json`
- Expected: JSON array of events in the specified range
- Edge cases: No events in range, invalid date format, date range spanning midnight

## Progress
- Implemented EventInfo model with Codable, human-readable output
- Implemented DateParser utility with multiple ISO 8601 format support
- Implemented ListEventsCommand with --from, --to, --calendar, --json options
- Modified: EventInfo.swift, DateParser.swift, ListEventsCommand.swift, AppleCalendarCLI.swift
- Verification: swift build passes

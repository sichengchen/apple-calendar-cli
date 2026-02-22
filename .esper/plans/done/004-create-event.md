---
id: 4
title: Create event command
status: done
type: feature
priority: 4
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
shipped_at: 2026-02-22
---
# Create event command

## Context
Depends on plans 002-003 (CalendarService, DateParser, models exist). EventKit allows creating events via `EKEvent` and saving with `EKEventStore.save(_:span:)`.

## Approach
1. Create `CreateEventCommand` subcommand with options:
   - `--title` (required)
   - `--start` (required, ISO 8601)
   - `--end` (required, ISO 8601)
   - `--calendar` (optional, calendar title or ID — defaults to default calendar)
   - `--notes` (optional)
   - `--location` (optional)
   - `--json` (output created event as JSON)
2. Validate inputs (end > start, calendar exists)
3. Create `EKEvent`, set properties, save to store
4. Output the created event (including its new ID) in human-readable or JSON format
5. Add unit tests for input validation

## Files to change
- `Sources/Commands/CreateEventCommand.swift` (create — subcommand)
- `Sources/Services/CalendarService.swift` (modify — add create method)
- `Sources/CalCLI.swift` (modify — register subcommand)
- `Tests/CreateEventTests.swift` (create — validation tests)

## Verification
- Run: `.build/debug/apple-calendar-cli create-event --title "Test" --start "2026-02-22T10:00:00" --end "2026-02-22T11:00:00"`
- Expected: Event created, prints event details with ID
- Run: `.build/debug/apple-calendar-cli create-event --title "Test" --start "2026-02-22T10:00:00" --end "2026-02-22T11:00:00" --json`
- Expected: JSON object with event ID, title, dates
- Edge cases: End before start, non-existent calendar name, overlapping events

## Progress
- Implemented CreateEventCommand with --title, --start, --end, --calendar, --notes, --location, --all-day, --url, --json
- Input validation: end > start, calendar exists, date parsing
- Modified: CreateEventCommand.swift, AppleCalendarCLI.swift
- Verification: swift build passes

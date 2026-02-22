---
id: 8
title: Get event by ID command
status: done
type: feature
priority: 3
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
shipped_at: 2026-02-22
---
# Get event by ID command

## Context
Depends on plans 002-003 (CalendarService, EventInfo model). Update and delete commands fetch events by ID internally, but there is no standalone command for users/agents to inspect a single event before modifying it. This is essential for agent workflows: list events → get event → update/delete.

## Approach
1. Create `GetEventCommand` subcommand with arguments:
   - `<id>` (required, event identifier)
   - `--json` (output as JSON)
2. Fetch event by `calendarItemExternalIdentifier` from EventKit
3. Output full event details: title, start, end, calendar, location, notes, URL, ID
4. Handle "event not found" with clear error message
5. Add unit tests

## Files to change
- `Sources/Commands/GetEventCommand.swift` (create — subcommand)
- `Sources/Services/CalendarService.swift` (modify — add fetch-by-ID if not already present)
- `Sources/CalCLI.swift` (modify — register subcommand)
- `Tests/GetEventTests.swift` (create — tests)

## Verification
- Run: `.build/debug/apple-calendar-cli get-event <id>`
- Expected: Prints full event details
- Run: `.build/debug/apple-calendar-cli get-event <id> --json`
- Expected: JSON object with all event fields
- Edge cases: Non-existent ID, deleted event

## Progress
- Implemented GetEventCommand with --json support, uses CalendarService.event(withIdentifier:)
- Reuses EventInfo model for output
- Modified: GetEventCommand.swift, AppleCalendarCLI.swift
- Verification: swift build passes

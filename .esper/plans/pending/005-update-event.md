---
id: 005
title: Update event command
status: pending
type: feature
priority: 5
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
---

# Update event command

## Context
Depends on plans 002-004 (CalendarService with create, models, date parsing). EventKit allows fetching events by `calendarItemExternalIdentifier` or `calendarItemIdentifier` and modifying properties.

## Approach
1. Create `UpdateEventCommand` subcommand with arguments:
   - `<id>` (required, event identifier)
   - `--title` (optional)
   - `--start` (optional, ISO 8601)
   - `--end` (optional, ISO 8601)
   - `--calendar` (optional — move event to different calendar)
   - `--notes` (optional)
   - `--location` (optional)
   - `--json` (output updated event as JSON)
2. Fetch the event by ID from EventKit
3. Apply only the provided fields (partial update)
4. Save and output the updated event
5. Handle "event not found" gracefully

## Files to change
- `Sources/Commands/UpdateEventCommand.swift` (create — subcommand)
- `Sources/Services/CalendarService.swift` (modify — add update/fetch-by-ID methods)
- `Sources/CalCLI.swift` (modify — register subcommand)
- `Tests/UpdateEventTests.swift` (create — validation tests)

## Verification
- Run: `.build/debug/apple-calendar-cli update-event <id> --title "Updated Title"`
- Expected: Event updated, prints new details
- Edge cases: Non-existent event ID, updating only one field, moving between calendars

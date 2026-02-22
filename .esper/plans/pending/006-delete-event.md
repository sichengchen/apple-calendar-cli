---
id: 006
title: Delete event command
status: pending
type: feature
priority: 6
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
---

# Delete event command

## Context
Depends on plans 002, 005 (CalendarService with fetch-by-ID). EventKit allows removing events via `EKEventStore.remove(_:span:)`.

## Approach
1. Create `DeleteEventCommand` subcommand with arguments:
   - `<id>` (required, event identifier)
   - `--json` (output confirmation as JSON)
2. Fetch event by ID
3. Remove from EventKit store
4. Output confirmation (deleted event title + ID)
5. Handle "event not found" gracefully

## Files to change
- `Sources/Commands/DeleteEventCommand.swift` (create — subcommand)
- `Sources/Services/CalendarService.swift` (modify — add delete method)
- `Sources/CalCLI.swift` (modify — register subcommand)
- `Tests/DeleteEventTests.swift` (create — tests)

## Verification
- Run: `.build/debug/apple-calendar-cli delete-event <id>`
- Expected: "Deleted event: <title> (<id>)"
- Run: `.build/debug/apple-calendar-cli delete-event <id> --json`
- Expected: JSON object with deleted event info
- Edge cases: Non-existent event ID, already deleted event

---
id: 009
title: Recurring event support
status: pending
type: feature
priority: 8
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
---

# Recurring event support

## Context
Depends on plans 003-006 (all CRUD commands). EventKit supports recurrence rules via `EKRecurrenceRule` — daily, weekly, monthly, yearly patterns. Currently, list-events will show individual occurrences but create/update commands cannot set recurrence.

## Approach
1. Add recurrence options to `create-event`:
   - `--recurrence` (daily, weekly, monthly, yearly)
   - `--interval` (e.g., every 2 weeks — defaults to 1)
   - `--end-recurrence` (ISO 8601 date for when recurrence stops, optional)
2. Add recurrence options to `update-event`:
   - Same flags as create
   - `--span` flag: `this` (this occurrence only) or `all` (all future occurrences)
3. Update `delete-event` with `--span` flag for recurring events
4. Show recurrence info in event output (list-events, get-event)
5. Add `isRecurring`, `recurrenceRule` fields to JSON output
6. Unit tests for recurrence rule construction

## Files to change
- `Sources/Commands/CreateEventCommand.swift` (modify — add recurrence flags)
- `Sources/Commands/UpdateEventCommand.swift` (modify — add recurrence + span flags)
- `Sources/Commands/DeleteEventCommand.swift` (modify — add span flag)
- `Sources/Models/EventInfo.swift` (modify — add recurrence fields)
- `Sources/Services/CalendarService.swift` (modify — handle EKRecurrenceRule)
- `Tests/RecurrenceTests.swift` (create — tests)

## Verification
- Run: `.build/debug/apple-calendar-cli create-event --title "Standup" --start "..." --end "..." --recurrence weekly`
- Expected: Creates recurring weekly event
- Run: `.build/debug/apple-calendar-cli list-events --from ... --to ...` on a range with recurrences
- Expected: Shows individual occurrences with recurrence info
- Edge cases: Deleting single occurrence vs all, updating recurrence pattern

---
id: 010
title: Attendee management
status: pending
type: feature
priority: 9
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
---

# Attendee management

## Context
Depends on plans 004-005 (create/update event). EventKit provides `EKParticipant` for attendees. Note: EventKit on macOS has limitations — you can read attendees but adding attendees programmatically requires the event to be on a CalDAV/Exchange calendar. Local calendars don't support attendees.

## Approach
1. Show attendees in event output (list-events, get-event):
   - Name, email, status (accepted/declined/pending), role (required/optional)
2. Add `--attendees` flag to `create-event` (comma-separated email addresses)
3. Add `--add-attendee` and `--remove-attendee` flags to `update-event`
4. Include attendee data in JSON output
5. Handle gracefully when calendar type doesn't support attendees
6. Unit tests for attendee parsing and output formatting

## Files to change
- `Sources/Commands/CreateEventCommand.swift` (modify — add attendees flag)
- `Sources/Commands/UpdateEventCommand.swift` (modify — add/remove attendee flags)
- `Sources/Models/EventInfo.swift` (modify — add attendee fields)
- `Sources/Models/AttendeeInfo.swift` (create — attendee data model)
- `Sources/Services/CalendarService.swift` (modify — handle attendees)
- `Tests/AttendeeTests.swift` (create — tests)

## Verification
- Run: `.build/debug/apple-calendar-cli get-event <id> --json` on event with attendees
- Expected: JSON includes attendees array with name, email, status
- Run: `.build/debug/apple-calendar-cli create-event ... --attendees "a@b.com,c@d.com"`
- Expected: Event created with attendees (on CalDAV calendar)
- Edge cases: Local calendar (no attendee support), invalid email, duplicate attendees

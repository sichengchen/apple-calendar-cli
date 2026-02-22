---
id: 11
title: Alert/notification configuration
status: done
type: feature
priority: 10
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
shipped_at: 2026-02-22
---
# Alert/notification configuration

## Context
Depends on plans 004-005 (create/update event). EventKit supports alerts via `EKAlarm` — relative offsets (e.g., 15 minutes before) or absolute dates. Calendar.app shows these as notification reminders.

## Approach
1. Add `--alert` flag to `create-event` (e.g., `--alert 15m`, `--alert 1h`, `--alert 1d`)
   - Support multiple alerts: `--alert 15m --alert 1h`
2. Add `--alert` and `--remove-alerts` flags to `update-event`
3. Show alerts in event output (list-events, get-event)
4. Parse alert shorthand: `5m`, `15m`, `30m`, `1h`, `2h`, `1d`, `2d`, `1w`
5. Include alerts in JSON output as array of offset values
6. Unit tests for alert parsing

## Files to change
- `Sources/Commands/CreateEventCommand.swift` (modify — add alert flag)
- `Sources/Commands/UpdateEventCommand.swift` (modify — add/remove alert flags)
- `Sources/Models/EventInfo.swift` (modify — add alerts field)
- `Sources/Utilities/AlertParser.swift` (create — parse alert shorthand)
- `Sources/Services/CalendarService.swift` (modify — handle EKAlarm)
- `Tests/AlertParserTests.swift` (create — tests)

## Verification
- Run: `.build/debug/apple-calendar-cli create-event ... --alert 15m --alert 1h`
- Expected: Event created with two alerts
- Run: `.build/debug/apple-calendar-cli get-event <id> --json`
- Expected: JSON includes alerts array
- Edge cases: Invalid alert format, removing all alerts, 0m offset

## Progress
- Created AlarmInfo model with relativeOffset and human-readable description
- Created AlertHelper utility for parsing offset strings (15m, 1h, 1d, etc.)
- Added --alert to create-event and update-event
- Added --remove-alerts flag to update-event
- Updated EventInfo to include alarms in JSON output and human-readable display
- Modified: AlarmInfo.swift, AlertHelper.swift, CreateEventCommand.swift, UpdateEventCommand.swift, EventInfo.swift
- Verification: swift build passes

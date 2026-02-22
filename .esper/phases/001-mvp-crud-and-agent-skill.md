---
phase: 001-mvp-crud-and-agent-skill
title: MVP — CRUD & Agent Skill
status: active
gh_issue: 1
---

# Phase 1: MVP — CRUD & Agent Skill

## Goal
Deliver a working Swift CLI that can list calendars, list/create/update/delete events on Apple Calendar via EventKit, with JSON output for machine consumption, and a Claude agent skill document so AI agents can use the CLI as a tool. Includes recurring events, attendees, alerts, and Homebrew distribution.

## In Scope
- Swift Package Manager project setup with ArgumentParser, XcodeGen
- .gitignore and Info.plist/entitlements for EventKit access
- List all calendars
- List events (with date range filtering)
- Get a single event by ID
- Create a new event (title, start, end, calendar, notes, location, recurrence, attendees, alerts)
- Update an existing event by ID (partial updates)
- Delete an existing event by ID
- Recurring event support (daily/weekly/monthly/yearly, span control)
- Attendee management (add/remove, display status)
- Alert/notification configuration (relative offsets)
- JSON output mode (`--json` flag) for all commands
- Human-readable default output
- Error handling with clear, actionable messages
- Claude agent skill document (`.claude/skills/` markdown)
- Unit tests for core logic
- SwiftLint configuration
- Homebrew formula & distribution

## Out of Scope (deferred)
- Natural language date parsing

## Acceptance Criteria
- [ ] `apple-calendar-cli list-calendars` prints all calendars (human-readable and JSON)
- [ ] `apple-calendar-cli list-events --from <date> --to <date>` lists events in a range
- [ ] `apple-calendar-cli get-event <id>` prints full event details
- [ ] `apple-calendar-cli create-event --title "..." --start "..." --end "..."` creates an event
- [ ] `apple-calendar-cli create-event ... --recurrence weekly` creates a recurring event
- [ ] `apple-calendar-cli create-event ... --attendees "a@b.com"` creates event with attendees
- [ ] `apple-calendar-cli create-event ... --alert 15m` creates event with alert
- [ ] `apple-calendar-cli update-event <id> --title "..."` updates an event
- [ ] `apple-calendar-cli delete-event <id>` deletes an event
- [ ] All commands support `--json` flag for structured output
- [ ] Claude agent skill document exists and is usable
- [ ] `swift test` passes
- [ ] `swiftlint` passes with no warnings
- [ ] `brew install` works from Homebrew formula

## Shipped Plans
- Plan 1 — Project scaffolding & SPM setup: Run `swift package init` and configure SPM with ArgumentParser + EventKit. Files: Package.swift, AppleCalendarCLI.swift, .swiftlint.yml, .gitignore, Info.plist
- Plan 2 — List calendars command: Create CalendarService wrapper around EKEventStore and ListCalendarsCommand subcommand. Files: CalendarService.swift, CalendarInfo.swift, ListCalendarsCommand.swift, AppleCalendarCLI.swift
- Plan 3 — List events command: Create ListEventsCommand with date range filtering and DateParser utility. Files: EventInfo.swift, DateParser.swift, ListEventsCommand.swift, AppleCalendarCLI.swift
- Plan 8 — Get event by ID command: Create GetEventCommand for fetching single event by identifier. Files: GetEventCommand.swift, AppleCalendarCLI.swift
- Plan 4 — Create event command: Create CreateEventCommand with title, start, end, calendar, notes, location, all-day, url options. Files: CreateEventCommand.swift, AppleCalendarCLI.swift
- Plan 5 — Update event command: Create UpdateEventCommand with partial update support for all event fields. Files: UpdateEventCommand.swift, AppleCalendarCLI.swift

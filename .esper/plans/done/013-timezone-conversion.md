---
id: 13
title: fix: dates output as UTC instead of local timezone
status: done
type: fix
priority: 1
phase: 001-mvp-crud-and-agent-skill
branch: fix/timezone-conversion
created: 2026-02-22
gh_issue: 3
shipped_at: 2026-02-22
---
# fix: dates output as UTC instead of local timezone

## Context

EventInfo.swift uses `ISO8601DateFormatter` with `.withInternetDateTime`, which always renders dates in UTC (with a `Z` suffix). Dates are parsed correctly in the user's local timezone by DateParser, but when displayed back, they appear shifted to UTC.

**Example**: User creates event at `2026-02-22T14:30:00` (local PST). EventInfo outputs `2026-02-22T22:30:00Z` — the user sees a UTC timestamp instead of their local time, making the output confusing and incorrect from the user's perspective.

The root cause is the static `formatter` in `EventInfo.swift` (line ~51-55):
```swift
private static nonisolated(unsafe) let formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()
```

`ISO8601DateFormatter` with `.withInternetDateTime` always normalizes to UTC. There is no mechanism to preserve or output the local timezone.

## Approach

1. **Change the output formatter** in `EventInfo.swift` to use a `DateFormatter` with ISO8601 format that respects the local timezone (e.g., `2026-02-22T14:30:00-08:00`) instead of converting to UTC with `Z`.
2. **Update the ISO8601 formatter** to include `.withTimeZone` and set `timeZone = .current` so output includes the local offset (e.g., `-08:00`) rather than `Z`.
3. **Update unit tests** in `DateParserTests.swift` to verify round-trip timezone behavior: parse a local datetime string, format it back, and confirm the local time components are preserved.

## Files to change

- `Sources/apple-calendar-cli/Models/EventInfo.swift` (modify — change formatter to output local timezone offset instead of UTC)
- `Tests/apple-calendar-cli-tests/DateParserTests.swift` (modify — add timezone round-trip tests)

## Verification

- Run: `swift test`
- Expected: All tests pass, including new timezone round-trip tests
- Manual check: `swift run apple-calendar-cli list-events --json` should output dates with local timezone offset (e.g., `-08:00`) instead of `Z`
- Regression check: create-event and update-event still parse dates correctly; list-events output remains valid ISO8601

## Progress
- Milestones: 3 commits
- Modified: Sources/apple-calendar-cli/Models/EventInfo.swift, Tests/apple-calendar-cli-tests/DateParserTests.swift
- Verification: not yet run — run /esper:finish to verify and archive

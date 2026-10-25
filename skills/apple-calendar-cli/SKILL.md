---
name: apple-calendar-cli
description: Manage Apple Calendar events on macOS with apple-calendar-cli. Use when listing calendars, finding or scheduling events, rescheduling meetings, or managing recurrence and alerts.
license: MIT
---

# Apple Calendar

Use `apple-calendar-cli` to work with the local Apple Calendar store through EventKit on macOS 14 or later. Use `--json` on calendar commands and inspect identifiers from their output rather than guessing an event or calendar ID.

## Setup and discovery

Check `apple-calendar-cli --version` and `apple-calendar-cli help`. For options not covered here, run `apple-calendar-cli help <command>`; the installed executable is authoritative.

If the CLI is missing, install it with `brew install sichengchen/tap/apple-calendar-cli` when the user requests installation. `apple-calendar-cli init` installs or updates this bundled skill for selected agents; it does not request Calendar access. In scripts, choose agents explicitly, for example `apple-calendar-cli init --agent codex --agent claude --agent pi`. Use `--scope project` for project skills and `--dry-run --json` to preview changes.

A Calendar command requests full access. If permission is missing, ask the user to run `apple-calendar-cli list-calendars` from a local interactive terminal. In **System Settings > Privacy & Security > Calendars**, access may be attributed to the launching app, such as Terminal or an agent's desktop app. A background or remote process may not present a permission dialog. Repeatedly retrying a denied request does not grant access.

## Dates and ranges

- `YYYY-MM-DD`: midnight in the local timezone.
- `YYYY-MM-DDTHH:MM:SS` or `YYYY-MM-DDTHH:MM`: local wall-clock time.
- `YYYY-MM-DDTHH:MM:SSZ` or a numeric offset: an explicit instant.
- JSON timestamps include an offset. Preserve it when rescheduling across timezones.
- The event end must be after its start. For an all-day event, use `--all-day` and the next date as the end of a single-day event.
- For a full-day search, use the following day's midnight as `--to`; equal `--from` and `--to` dates do not represent the full day. An omitted `--to` defaults to seven days after the search start.

Resolve an ambiguous date, timezone, or recurring-event scope before changing the calendar.

## Read commands

```bash
apple-calendar-cli list-calendars --json
apple-calendar-cli list-events --json
apple-calendar-cli list-events --from 2026-10-13 --to 2026-10-14 --json
apple-calendar-cli list-events --from 2026-10-13 --to 2026-10-20 --calendar CALENDAR-ID --json
apple-calendar-cli get-event EVENT-ID --json
```

`list-events` defaults to the start of today through the next seven days. Choose a bounded range when searching for a particular event. `get-event` reads the event using the identifier returned by a listing.

## Create events

```bash
apple-calendar-cli create-event \
  --title "Planning" \
  --start "2026-10-13T10:00:00" \
  --end "2026-10-13T10:30:00" \
  --calendar CALENDAR-ID \
  --alert 15m \
  --json
```

Required: `--title`, `--start`, `--end`.

Optional: `--calendar`, `--notes`, `--location`, `--all-day`, `--url`, `--alert`, `--attendees`, `--recurrence`, `--interval`, `--recurrence-end`, `--recurrence-count`.

Without `--calendar`, the default calendar receives the event. Use `list-calendars` to identify the requested destination.

Creating an event is not idempotent. If a create command's outcome is uncertain, list the intended time range before retrying to avoid a duplicate.

`--attendees` takes comma-separated emails and appends them to the event's **notes**. It does not add EventKit participants or send invitations. Do not describe an event created with this flag as an invitation.

## Update events

```bash
apple-calendar-cli update-event EVENT-ID --title "Updated planning" --json
apple-calendar-cli update-event EVENT-ID \
  --start "2026-10-13T11:00:00" \
  --end "2026-10-13T11:30:00" \
  --location "Room B" \
  --json
```

Only supplied fields change. Accepted fields: `--title`, `--start`, `--end`, `--calendar`, `--notes`, `--location`, `--url`, `--recurrence`, `--interval`, `--recurrence-end`, `--recurrence-count`, `--alert`, `--remove-alerts`, `--span`, `--occurrence`.

For a time shift, provide both start and end to preserve the desired duration; changing start alone leaves the old end in place. Updating supports neither `--all-day` nor `--attendees`.

`--alert` adds an alarm. `--remove-alerts` removes every existing alarm. Use both together to replace the alert list with one new alarm:

```bash
apple-calendar-cli update-event EVENT-ID --remove-alerts --alert 30m --json
```

## Recurrence and deletion

Create or replace recurrence with `--recurrence daily|weekly|monthly|yearly`. `--interval N` defaults to `1`. Use a positive interval and either `--recurrence-end DATE` or `--recurrence-count N` when a bounded series is intended. If both end conditions are supplied, the end date takes precedence.

On update, `--recurrence` replaces all existing recurrence rules. Omitted recurrence settings are not preserved: the interval resets to `1`, and omitting both end conditions makes the new series indefinite. `--interval`, `--recurrence-end`, and `--recurrence-count` have no effect without a frequency in `--recurrence`. Use `--recurrence none` on update to remove recurrence.

All occurrences of a recurring event share one identifier. Address one with `--occurrence`, set to that occurrence's `occurrenceDate` from `list-events --json` (its original start, even if the occurrence has moved). Choose the scope with `--span`:

- `this` (default): only the addressed occurrence. Requires `--occurrence`.
- `future`: the addressed occurrence and every later one. Requires `--occurrence`.
- `all`: the whole series, including past occurrences. Don't pass `--occurrence` with it.

Update or delete of a recurring event with `this` or `future` and no `--occurrence` fails instead of touching the first occurrence. Confirm the occurrence and scope with the user before a series change.

A moved or edited occurrence has its own identifier, `<series identifier>/RID=<n>`; it can be passed without `--occurrence`, regardless of how far it moved. With an exact identifier, an optional `--occurrence` must match its original or current start. If original-date lookup fails for a moved occurrence, use its exact identifier from `list-events --json`; do not substitute its current start with a series identifier. A `future` change splits the series and gives the later occurrences a new identifier, so re-list before the next change. A `future` delete also removes later occurrences that an earlier `future` edit split off (EventKit behaviour): list the range first and check what will go.

```bash
apple-calendar-cli update-event EVENT-ID --occurrence "2026-10-13T11:00:00" \
  --start "2026-10-13T12:00:00" --end "2026-10-13T12:30:00" --json

apple-calendar-cli update-event EVENT-ID \
  --recurrence weekly --interval 2 --recurrence-count 10 --span all --json

apple-calendar-cli delete-event EVENT-ID --occurrence "2026-10-13T11:00:00" --json
apple-calendar-cli delete-event EVENT-ID --occurrence "2026-10-13T11:00:00" --span future --json
apple-calendar-cli delete-event EVENT-ID --span all --json
```

An event identifier may change after a recurrence edit. Re-list the range when a later lookup reports that the event was not found.

Alert offsets use `s`, `m`, `h`, `d`, or `w`, such as `30s`, `15m`, `1h`, `1d`, or `1w`, and describe time **before** the event.

## JSON output

`list-calendars` returns an array with these fields:

| Field | Type |
| --- | --- |
| `identifier`, `title`, `type`, `source`, `color` | string |
| `isImmutable` | boolean |

`list-events` returns an array of event objects. `get-event`, `create-event`, and `update-event` return one event object:

| Field | Type |
| --- | --- |
| `identifier`, `title`, `startDate`, `endDate` | string |
| `calendarTitle`, `calendarIdentifier` | string |
| `isAllDay`, `hasRecurrenceRules`, `hasAlarms` | boolean |
| `location`, `notes`, `url` | optional string |
| `occurrenceDate` | optional string; recurring events only — pass it as `--occurrence` |
| `recurrenceRules` | optional array of recurrence rules |
| `attendees` | optional array of participants |
| `alarms` | optional array of alarms |

Optional properties are omitted when unavailable; do not assume they exist or contain `null`.

- Recurrence rule: `frequency` (string), `interval` (integer), optional `endDate` (string) or `occurrenceCount` (integer).
- Participant: optional `name` and `email` (strings), `status` and `role` (strings).
- Alarm: `relativeOffset` (seconds, usually negative), `offsetDescription` (string).
- Deletion: `{ "deleted": true, "event": <the event object before deletion> }`.
- Skill setup: an array of `{ "agent": <agent key>, "path": <SKILL.md path>, "action": <result> }`, with optional `backup` or `error`. Results are `installed`, `updated`, `unchanged`, `would-install`, `would-update`, or `failed`.

Treat a nonzero exit status as failure, even with `--json`. Errors are not guaranteed to be JSON. If skill installation partially fails, successful targets remain installed and the JSON results identify the failed targets.

## Workflow: find and reschedule

1. List a narrow date range with `list-events --json`; add `--calendar` when known.
2. Match the title and time, then use `get-event` if more detail is needed. Resolve multiple matches with the user.
3. Update the chosen identifier with both new start and end. For a recurring event, also pass its `occurrenceDate` as `--occurrence` and the intended `--span`.
4. Report the resulting date, time, timezone, and calendar from the returned event rather than assuming the change succeeded.

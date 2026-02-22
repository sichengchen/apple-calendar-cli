# apple-calendar-cli

A command-line tool for Apple Calendar (Calendar.app) operations via EventKit. Supports listing calendars, listing/creating/updating/deleting events, recurring events, alerts, and JSON output for machine consumption.

macOS 14+ only.

## Install

### Homebrew

```bash
brew install sichengchen/tap/apple-calendar-cli
```

### Build from source

```bash
git clone https://github.com/sichengchen/apple-calendar-cli.git
cd apple-calendar-cli
make install
```

## Usage

All commands support `--json` for structured JSON output.

### List calendars

```bash
apple-calendar-cli list-calendars
apple-calendar-cli list-calendars --json
```

### List events

```bash
# Next 7 days (default)
apple-calendar-cli list-events

# Specific date range
apple-calendar-cli list-events --from 2026-02-22 --to 2026-02-28

# Filter by calendar
apple-calendar-cli list-events --calendar CALENDAR-ID --json
```

### Get event

```bash
apple-calendar-cli get-event EVENT-ID
apple-calendar-cli get-event EVENT-ID --json
```

### Create event

```bash
apple-calendar-cli create-event \
  --title "Meeting" \
  --start "2026-02-23T14:00:00" \
  --end "2026-02-23T15:00:00"

# With all options
apple-calendar-cli create-event \
  --title "Weekly standup" \
  --start "2026-02-23T10:00:00" \
  --end "2026-02-23T10:30:00" \
  --calendar CALENDAR-ID \
  --location "Conference Room" \
  --notes "Discuss sprint progress" \
  --recurrence weekly \
  --alert 15m \
  --json
```

### Update event

```bash
# Partial update — only specified fields change
apple-calendar-cli update-event EVENT-ID --title "New title"
apple-calendar-cli update-event EVENT-ID \
  --start "2026-02-24T14:00:00" \
  --end "2026-02-24T15:00:00" \
  --location "Room B"

# Recurring event — update all future occurrences
apple-calendar-cli update-event EVENT-ID --title "Updated" --span all
```

### Delete event

```bash
apple-calendar-cli delete-event EVENT-ID

# Delete all occurrences of a recurring event
apple-calendar-cli delete-event EVENT-ID --span all
```

## Date formats

- Date only: `YYYY-MM-DD` (start of day, local timezone)
- Date and time: `YYYY-MM-DDTHH:MM:SS` (local timezone)
- Full ISO 8601: `YYYY-MM-DDTHH:MM:SSZ`

## Alert formats

- `30s` — 30 seconds before
- `15m` — 15 minutes before
- `1h` — 1 hour before
- `1d` — 1 day before
- `1w` — 1 week before

## Recurrence

- `--recurrence daily|weekly|monthly|yearly`
- `--interval N` — every N periods (default: 1)
- `--recurrence-end YYYY-MM-DD` — stop recurring after date
- `--recurrence-count N` — stop after N occurrences

## Permissions

On first run, macOS will prompt for calendar access. If denied, grant access in **System Settings > Privacy & Security > Calendars**.

## AI agent usage

A Claude agent skill document is included at [`skills/apple-calendar-cli.md`](skills/apple-calendar-cli.md) with full command reference, JSON schemas, and common workflows.

## License

MIT

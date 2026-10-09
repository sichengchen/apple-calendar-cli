# apple-calendar-cli

A command-line tool for Apple Calendar (Calendar.app) operations via EventKit. Supports listing calendars, listing/creating/updating/deleting events, recurring events, alerts, and JSON output for machine consumption.

macOS 14+ only.

## AI agent usage

Run `apple-calendar-cli init` to install or update the bundled [agent skill](skills/apple-calendar-cli/SKILL.md). It works offline and includes the command reference, JSON fields, and Calendar workflows.

Use Up/Down to move, Space to select agents, and Enter to install. Detected agents are selected initially; you can choose other agents too. Existing skills are compared with the bundled copy: matching files stay untouched, and updates save a `.bak` copy of the previous `SKILL.md` while preserving other files in the skill folder.

For scripts or project-specific setup:

```bash
apple-calendar-cli init --agent codex --agent claude --agent pi
apple-calendar-cli init --scope project --agent antigravity
apple-calendar-cli init --agent codex --dry-run --json
```

Each target installs `apple-calendar-cli/SKILL.md` in the following directory:

| Agent | User directory | Project directory |
| --- | --- | --- |
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `~/.agents/skills` | `.agents/skills` |
| [Claude Code](https://code.claude.com/docs/en/skills) | `~/.claude/skills` | `.claude/skills` |
| [Pi](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md) | `~/.pi/agent/skills` | `.pi/skills` |
| [Antigravity CLI](https://www.antigravity.google/docs/skills?tab=cli) | `~/.gemini/antigravity-cli/skills` | `.agents/skills` |
| [Antigravity IDE](https://www.antigravity.google/docs/skills?tab=ide) | `~/.gemini/config/skills` | `.agents/skills` |
| [OpenCode](https://opencode.ai/docs/skills/) | `~/.config/opencode/skills` | `.opencode/skills` |

User installations honor `CLAUDE_CONFIG_DIR`, `PI_CODING_AGENT_DIR`, and `XDG_CONFIG_HOME`. Codex's `.agents/skills` directory is shared with compatible agents; they may also discover a skill installed there. Symlinked skill folders or files are left for their owner to update. Reload skills or start a new agent session after installation.

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

Calendar commands and `init` support `--json` for structured JSON output.

### Help

```bash
apple-calendar-cli help
apple-calendar-cli help init
apple-calendar-cli help create-event
```

`help` lists usage and available commands. `help <command>` lists that command's options; `--help` is also supported.

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

Run `apple-calendar-cli list-calendars` interactively to request full Calendar access. The executable embeds its Calendar usage descriptions, so a Homebrew installation does not need a separate `Info.plist` or app bundle.

macOS may attribute a command-line permission request to the app that launches it, such as Terminal or an agent's desktop app. If access is denied, check **System Settings > Privacy & Security > Calendars** for that app as well as `apple-calendar-cli`. A background or remote session may not be able to present a permission dialog; make the initial request from a local terminal.

## Releases

Run **Cut release** in GitHub Actions on `main` and choose `patch`, `minor`, or `major`. With the GitHub CLI installed and authenticated, you can also run:

```bash
./scripts/release.sh patch
```

The workflow bumps the CLI version on `main`, tests and builds that exact commit on macOS, smoke tests the binary, then creates a `vX.Y.Z` tag and GitHub release with an ARM64 tarball and generated release notes. It also updates the source-based formula in `sichengchen/homebrew-tap`.

Configure the repository secret `TAP_GITHUB_TOKEN` with write access to `sichengchen/homebrew-tap`. The workflow's `GITHUB_TOKEN` must be allowed to push commits to `main` and create release tags. Missing tap credentials stop the workflow before the version changes.

If publishing fails, use **Re-run failed jobs** to retry the same release commit. Starting a new workflow run bumps the version again. Pushing a tag manually no longer publishes a release.

## License

MIT

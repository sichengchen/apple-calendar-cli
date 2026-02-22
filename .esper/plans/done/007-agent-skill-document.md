---
id: 7
title: Claude agent skill document
status: done
type: feature
priority: 7
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
shipped_at: 2026-02-22
---
# Claude agent skill document

## Context
Depends on plans 001-006 (all CLI commands implemented). The skill document teaches Claude agents how to use the CLI as a tool — command syntax, expected inputs/outputs, and usage patterns.

## Approach
1. Create a Claude agent skill markdown file in the project
2. Document every subcommand with:
   - Purpose and when to use it
   - Full argument/option reference
   - Example invocations with expected output
   - JSON output schema for each command
3. Include guidance on:
   - Permission handling (Calendar access)
   - Date format requirements (ISO 8601)
   - Error handling patterns
   - Common workflows (e.g., "find an event then update it")
4. Install/reference instructions for agents

## Files to change
- `skills/apple-calendar-cli.md` (create — agent skill document)

## Verification
- Manual review: skill document is comprehensive and accurate
- Expected: An AI agent reading the skill can invoke all commands correctly
- Edge cases: Document covers error scenarios and permission issues

## Progress
- Created comprehensive skill document at skills/apple-calendar-cli.md
- Documents all 6 commands with full option reference, JSON schemas, example invocations
- Includes common agent workflows, date format guide, error handling
- Also fixed root command to AsyncParsableCommand for async subcommands
- Modified: skills/apple-calendar-cli.md, AppleCalendarCLI.swift
- Verification: manual review — document is comprehensive and accurate

---
id: 012
title: Homebrew formula & distribution
status: pending
type: feature
priority: 11
phase: 001-mvp-crud-and-agent-skill
branch: feature/001-mvp-crud-and-agent-skill
created: 2026-02-21
---

# Homebrew formula & distribution

## Context
Depends on all prior plans (CLI must be feature-complete). Users need a simple `brew install` path. Since this is a Swift CLI on macOS, the formula will build from source using `swift build -c release`.

## Approach
1. Create a Homebrew formula (`Formula/apple-calendar-cli.rb` or in a separate tap repo)
2. Formula should:
   - Point to the GitHub repo tarball for the release
   - Build from source with `swift build -c release`
   - Install the binary to the Homebrew prefix
   - Declare macOS-only (`depends_on :macos`)
3. Add a `Makefile` or build script for release builds
4. Add installation instructions to README
5. Create a GitHub release workflow (optional — can be manual for MVP)
6. Test `brew install --build-from-source` locally

## Files to change
- `Formula/apple-calendar-cli.rb` (create — Homebrew formula)
- `Makefile` (create — release build + install targets)
- `README.md` (create — installation and usage instructions)

## Verification
- Run: `swift build -c release`
- Expected: Produces optimized binary
- Run: `brew install --build-from-source ./Formula/apple-calendar-cli.rb` (local test)
- Expected: CLI installed and available as `apple-calendar-cli`
- Edge cases: Xcode command-line tools version, macOS version requirements

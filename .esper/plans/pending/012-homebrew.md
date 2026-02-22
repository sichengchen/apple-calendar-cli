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
Depends on all prior plans (CLI must be feature-complete). Users need a simple `brew install` path. Since this is a Swift CLI on macOS, the formula will build from source using `swift build -c release`. A Homebrew tap repo already exists at `sichengchen/homebrew-tap`. CI/CD via GitHub Actions will automate building, releasing, and updating the tap formula on each tagged release.

## Approach
1. **GitHub Actions CI workflow** (`.github/workflows/ci.yml`)
   - Triggers on push to `main` and on PRs
   - Runs `swift build` and `swift test` on macOS runner
   - Ensures every commit is buildable and tested
2. **GitHub Actions release workflow** (`.github/workflows/release.yml`)
   - Triggers on version tags (`v*`)
   - Builds release binary with `swift build -c release`
   - Creates a GitHub Release with the binary attached as an artifact
   - Computes the SHA256 of the release tarball
   - Updates the Homebrew formula in `sichengchen/homebrew-tap` with the new version URL and SHA256 (via a dispatch or direct commit using a PAT)
3. **Homebrew formula** in `sichengchen/homebrew-tap` (not in this repo)
   - Formula at `Formula/apple-calendar-cli.rb` in the tap repo
   - Points to the GitHub release tarball
   - Builds from source with `swift build -c release`
   - Installs the binary to the Homebrew prefix
   - Declares macOS-only (`depends_on :macos`)
4. Add a `Makefile` with release build + install targets for local use
5. Add installation instructions to README (`brew install sichengchen/tap/apple-calendar-cli`)
6. Test full flow: tag → CI builds → release created → tap formula updated → `brew install` works

## Files to change
- `.github/workflows/ci.yml` (create — CI workflow: build + test on PRs and main)
- `.github/workflows/release.yml` (create — release workflow: build, GitHub Release, update tap)
- `Makefile` (create — release build + install targets for local use)
- `README.md` (create — installation and usage instructions)
- `sichengchen/homebrew-tap: Formula/apple-calendar-cli.rb` (create — Homebrew formula in tap repo, updated automatically by release workflow)

## Verification
- Run: `swift build -c release`
- Expected: Produces optimized binary
- Push a version tag (e.g. `v0.1.0`)
- Expected: GitHub Actions release workflow triggers, creates a GitHub Release with binary artifact, and updates the formula in `sichengchen/homebrew-tap`
- Run: `brew install sichengchen/tap/apple-calendar-cli`
- Expected: CLI installed and available as `apple-calendar-cli`
- Run: `brew test apple-calendar-cli` (if test block is defined in formula)
- Expected: Basic smoke test passes
- Edge cases: Xcode CLI tools version, macOS version requirements, PAT permissions for tap repo updates

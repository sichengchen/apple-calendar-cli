#!/bin/bash
set -euo pipefail

SWIFT_FILE="Sources/apple-calendar-cli/AppleCalendarCLI.swift"

# Get current version from source
CURRENT=$(grep 'version:' "$SWIFT_FILE" | sed 's/.*version: "\(.*\)".*/\1/')
echo "Current version: $CURRENT"

# Parse semver
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# Determine bump type
BUMP="${1:-patch}"
case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *) echo "Usage: $0 [major|minor|patch]"; exit 1 ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version: $NEW_VERSION"

# Bump version in source
sed -i '' "s/version: \"$CURRENT\"/version: \"$NEW_VERSION\"/" "$SWIFT_FILE"

# Build to verify
echo "Building..."
swift build -c release 2>&1 | tail -1

# Commit, tag, push
git add "$SWIFT_FILE"
git commit -m "release: v$NEW_VERSION"
git tag "v$NEW_VERSION"
git push
git push origin "v$NEW_VERSION"

echo "Released v$NEW_VERSION"

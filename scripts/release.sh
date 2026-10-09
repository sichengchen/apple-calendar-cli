#!/bin/bash
set -euo pipefail

BUMP="${1:-patch}"
if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [major|minor|patch]" >&2
  exit 1
fi

case "$BUMP" in
  major|minor|patch) ;;
  *) echo "Usage: $0 [major|minor|patch]" >&2; exit 1 ;;
esac

gh workflow run cut-release.yml \
  --repo sichengchen/apple-calendar-cli \
  --ref main \
  --field "bump=$BUMP"

echo "Requested a $BUMP release from main."
echo "Track progress: https://github.com/sichengchen/apple-calendar-cli/actions/workflows/cut-release.yml"

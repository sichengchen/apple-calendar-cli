#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <apple-calendar-cli binary>" >&2
  exit 1
fi

plist="$(xcrun otool -X -P "$1")"
if [[ -z "$plist" ]]; then
  echo "Calendar permission metadata is missing from $1" >&2
  exit 1
fi

description="$(printf '%s' "$plist" | plutil -extract NSCalendarsFullAccessUsageDescription raw -o - -)"
identifier="$(printf '%s' "$plist" | plutil -extract CFBundleIdentifier raw -o - -)"
if [[ -z "$description" || "$identifier" != "com.scchan.apple-calendar-cli" ]]; then
  echo "Calendar permission metadata is invalid in $1" >&2
  exit 1
fi

codesign --verify --strict -R '=identifier "com.scchan.apple-calendar-cli"' "$1"

echo "Calendar permission metadata verified in $1"

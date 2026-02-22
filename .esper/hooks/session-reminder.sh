#!/usr/bin/env bash
REMINDERS=()

UNCOMMITTED=$(git status --porcelain 2>/dev/null)
if [ -n "$UNCOMMITTED" ]; then
  CHANGED=$(echo "$UNCOMMITTED" | wc -l | tr -d ' ')
  REMINDERS+=("  ! $CHANGED uncommitted file(s) — run /esper:finish when ready")
fi

ACTIVE_PLANS=$(ls .esper/plans/active/*.md 2>/dev/null)
if [ -n "$ACTIVE_PLANS" ]; then
  PLAN=$(head -5 .esper/plans/active/*.md | grep '^title:' | head -1 | sed 's/title: //')
  REMINDERS+=("  > active plan: $PLAN")
fi

PENDING=$(ls .esper/plans/pending/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$PENDING" -gt 0 ]; then
  REMINDERS+=("  · $PENDING pending item(s) in backlog — run /esper:backlog to review")
fi

if [ ${#REMINDERS[@]} -gt 0 ]; then
  echo ""
  echo "esper:"
  for r in "${REMINDERS[@]}"; do echo "$r"; done
fi

exit 0

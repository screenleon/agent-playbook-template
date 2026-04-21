#!/usr/bin/env bash
# decision-capture.sh — Extract and record decisions from the current git diff.
#
# Reads the working-tree diff and looks for changes to DECISIONS.md.
# When decision_log.policy=example_only (template repos), decisions go to
# .harness/decisions-<pack_id>.log instead of DECISIONS.md.
#
# Usage:
#   bash harness/core/decision-capture.sh
#   HARNESS_PACK_ID=ctx_001 bash harness/core/decision-capture.sh
#
# Outputs:
#   Appends to .harness/decisions-<pack_id>.log
#   Prints a summary to stdout
#
# Exit codes:
#   0  OK (decisions captured or none found — both are non-blocking)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HARNESS_DIR="$REPO_ROOT/.harness"
PACK_ID="${HARNESS_PACK_ID:-unknown}"
POLICY="${HARNESS_DECISION_POLICY:-normal}"

mkdir -p "$HARNESS_DIR"
LOG_FILE="$HARNESS_DIR/decisions-${PACK_ID}.log"

# ── Detect DECISIONS.md changes in working tree ───────────────────────────────
DECISIONS_DIFF=$(git -C "$REPO_ROOT" diff HEAD -- DECISIONS.md 2>/dev/null || true)
DECISIONS_STAGED=$(git -C "$REPO_ROOT" diff --cached -- DECISIONS.md 2>/dev/null || true)

COMBINED_DIFF="${DECISIONS_DIFF}${DECISIONS_STAGED}"

if [ -z "$COMBINED_DIFF" ]; then
  echo "[HARNESS DECISIONS] No DECISIONS.md changes detected in working tree." >&2
  exit 0
fi

# ── Extract added lines (new decision entries) ────────────────────────────────
ADDED_LINES=$(echo "$COMBINED_DIFF" | grep '^+' | grep -v '^+++' | sed 's/^+//' || true)

if [ -z "$ADDED_LINES" ]; then
  echo "[HARNESS DECISIONS] DECISIONS.md changed but no new lines added." >&2
  exit 0
fi

# ── Route based on decision_log.policy ───────────────────────────────────────
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ "$POLICY" = "example_only" ]; then
  # Template repo mode: write to .harness/ sidecar instead of DECISIONS.md
  {
    echo "## Decision capture — $TIMESTAMP"
    echo "Pack: $PACK_ID"
    echo "Policy: example_only (captured here instead of DECISIONS.md)"
    echo ""
    echo "$ADDED_LINES"
    echo ""
  } >> "$LOG_FILE"
  echo "[HARNESS DECISIONS] example_only: decisions captured to $LOG_FILE" >&2
else
  # Normal mode: DECISIONS.md already contains the changes — just log metadata
  {
    echo "## Decision capture — $TIMESTAMP"
    echo "Pack: $PACK_ID"
    echo "Policy: normal (written directly to DECISIONS.md)"
    echo "Lines added: $(echo "$ADDED_LINES" | wc -l | tr -d ' ')"
    echo ""
  } >> "$LOG_FILE"
  echo "[HARNESS DECISIONS] normal: DECISIONS.md updated. Metadata at $LOG_FILE" >&2
fi

echo "[HARNESS DECISIONS] Done." >&2
exit 0

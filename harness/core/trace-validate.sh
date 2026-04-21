#!/usr/bin/env bash
# trace-validate.sh — Verify that a trace record was emitted for the current task.
#
# Called as a Claude Code Stop hook or directly after task completion.
# Checks for a new or updated .agent-trace/*.trace.yaml within the last N minutes.
#
# Exit codes:
#   0  PASS    — trace found
#   1  MISSING — no recent trace (severity depends on task scale)
#   2  MALFORMED — trace file exists but fails basic structure check
#
# Environment:
#   HARNESS_BUDGET_PROFILE   nano|minimal|standard|full (default: standard)
#   HARNESS_TASK_SCALE       Small|Medium|Large (default: Medium)
#   HARNESS_TRACE_WINDOW_MIN how many minutes back to look (default: 60)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TRACE_DIR="$REPO_ROOT/.agent-trace"
PROFILE="${HARNESS_BUDGET_PROFILE:-standard}"
TASK_SCALE="${HARNESS_TASK_SCALE:-Medium}"
WINDOW="${HARNESS_TRACE_WINDOW_MIN:-60}"

# Nano profile: traces are optional — agents inline them in task summary
if [ "$PROFILE" = "nano" ]; then
  echo "[HARNESS TRACE] nano profile — trace emission is optional. PASS." >&2
  exit 0
fi

# Small tasks at minimal profile: inline trace is acceptable; don't hard-block
_soft_pass() {
  echo "[HARNESS TRACE] $1 ADVISORY (not blocking)." >&2
  exit 0
}

_fail() {
  local code="$1"; shift
  echo "[HARNESS TRACE] $*" >&2
  exit "$code"
}

# ── Check trace directory exists ──────────────────────────────────────────────
if [ ! -d "$TRACE_DIR" ]; then
  if [ "$TASK_SCALE" = "Small" ]; then
    _soft_pass "No .agent-trace/ directory. Small task — inline trace acceptable."
  fi
  _fail 1 "MISSING: .agent-trace/ directory does not exist. Emit a trace record per docs/agent-playbook.md → Mandatory steps (step 14)."
fi

# ── Find recent trace files ───────────────────────────────────────────────────
# Use find with -mmin; macOS and Linux both support this
RECENT_TRACES=$(find "$TRACE_DIR" -name "*.trace.yaml" -mmin "-${WINDOW}" 2>/dev/null | head -20)

if [ -z "$RECENT_TRACES" ]; then
  if [ "$TASK_SCALE" = "Small" ] && [ "$PROFILE" = "minimal" ]; then
    _soft_pass "No recent trace. Small+minimal — inline trace acceptable."
  fi
  _fail 1 "MISSING: No .trace.yaml file modified in the last ${WINDOW} minutes. Emit a trace record before marking this task complete."
fi

# ── Basic structure check on most recent trace ────────────────────────────────
LATEST=$(echo "$RECENT_TRACES" | sort | tail -1)

if ! command -v python3 &>/dev/null; then
  echo "[HARNESS TRACE] PASS — trace found at $LATEST (structure check skipped: python3 unavailable)." >&2
  exit 0
fi

python3 - "$LATEST" <<'PYEOF'
import sys, re

path = sys.argv[1]
required_fields = ['task_id', 'role', 'task_scale', 'validation_outcome']

try:
    with open(path) as f:
        content = f.read()
except Exception as e:
    print(f"[HARNESS TRACE] ERROR reading {path}: {e}", file=sys.stderr)
    sys.exit(2)

missing = [f for f in required_fields if not re.search(rf'^{f}:', content, re.MULTILINE)]

if missing:
    print(f"[HARNESS TRACE] MALFORMED: {path} is missing required fields: {missing}", file=sys.stderr)
    print(f"Required: {required_fields}", file=sys.stderr)
    sys.exit(2)

# Check for validation failure
if re.search(r'^validation_outcome:\s*["\']?fail["\']?', content, re.MULTILINE):
    print(f"[HARNESS TRACE] WARNING: {path} reports validation_outcome: fail", file=sys.stderr)
    # Don't block — let agent-review.sh handle severity in CI
    sys.exit(0)

print(f"[HARNESS TRACE] PASS — {path}", file=sys.stderr)
sys.exit(0)
PYEOF

#!/usr/bin/env bash
# pre-invoke.sh — Generic PRE phase: bootstrap + context pack assembly + gate check.
#
# Run this before invoking any agent tool that has no native PreToolUse hook.
# Exports harness environment variables into the current shell.
#
# Usage:
#   eval "$(bash harness/adapters/generic/pre-invoke.sh)"
#
# Optional env inputs:
#   HARNESS_ROLE, HARNESS_INTENT_MODE, HARNESS_TASK_SCALE
#   HARNESS_OBJECTIVE, HARNESS_SCOPE_SUMMARY
#   HARNESS_WRITE_PACK=1  to write .harness/context-pack.json

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "[HARNESS PRE] Starting generic pre-invoke..." >&2

# ── 1. Bootstrap — read prompt-budget.yml and export env vars ─────────────────
BOOTSTRAP_OUT=$(bash "$REPO_ROOT/harness/bootstrap.sh")
eval "$BOOTSTRAP_OUT"

echo "[HARNESS PRE] Tool=$HARNESS_TOOL  Mode=$HARNESS_EXECUTION_MODE  Profile=$HARNESS_BUDGET_PROFILE" >&2

# ── 2. Pack validation (if pack exists from a previous step) ──────────────────
if [ -f "$REPO_ROOT/.harness/context-pack.json" ]; then
  bash "$REPO_ROOT/harness/core/pack-validate.sh" "$REPO_ROOT/.harness/context-pack.json" || true
fi

# ── 3. Gate check on declared operation ───────────────────────────────────────
# In generic mode there is no per-tool-call hook, so we check the declared intent.
# Agents are expected to self-report dangerous operations via HARNESS_DECLARED_OP.
DECLARED_OP="${HARNESS_DECLARED_OP:-}"
if [ -n "$DECLARED_OP" ]; then
  echo "[HARNESS PRE] Gate check for declared operation: $DECLARED_OP" >&2
  bash "$REPO_ROOT/harness/core/gate-check.sh" "Generic" "$DECLARED_OP" || {
    EXIT=$?
    if [ $EXIT -eq 1 ]; then
      echo "[HARNESS PRE] STOP: Operation blocked by gate check. Aborting." >&2
      exit 1
    fi
  }
fi

# ── 4. Print Layer 1 files for the agent to load ─────────────────────────────
echo "[HARNESS PRE] Layer 1 context files to load:" >&2
for f in $HARNESS_LAYER1_FILES; do
  if [ -f "$REPO_ROOT/$f" ]; then
    echo "  ✓ $f" >&2
  else
    echo "  ✗ $f (NOT FOUND)" >&2
  fi
done

# ── 5. Re-emit the bootstrap exports so callers can eval this script ──────────
echo "$BOOTSTRAP_OUT"

echo "[HARNESS PRE] Pack ID: $HARNESS_PACK_ID  Trace ID: $HARNESS_TRACE_ID" >&2
echo "[HARNESS PRE] Done." >&2

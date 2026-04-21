#!/usr/bin/env bash
# post-invoke.sh — Generic POST phase: trace validation + decision capture.
#
# Run this after the agent tool completes when there are no native Stop hooks.
# Exits non-zero only when HARNESS_REQUIRE_TRACE=1 and no trace is found.
#
# Usage:
#   bash harness/adapters/generic/post-invoke.sh
#
# Environment (inherited from pre-invoke or set manually):
#   HARNESS_PACK_ID, HARNESS_TRACE_ID, HARNESS_BUDGET_PROFILE
#   HARNESS_DECISION_POLICY, HARNESS_TASK_SCALE
#   HARNESS_REQUIRE_TRACE=1  to make missing trace a hard failure

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "[HARNESS POST] Starting generic post-invoke..." >&2

# ── Bootstrap if env vars not already set ─────────────────────────────────────
if [ -z "${HARNESS_PACK_ID:-}" ]; then
  echo "[HARNESS POST] Env not bootstrapped — running bootstrap." >&2
  eval "$(bash "$REPO_ROOT/harness/bootstrap.sh")"
fi

# ── 1. Trace validation ───────────────────────────────────────────────────────
TRACE_EXIT=0
bash "$REPO_ROOT/harness/core/trace-validate.sh" || TRACE_EXIT=$?

case $TRACE_EXIT in
  0) echo "[HARNESS POST] Trace: PASS" >&2 ;;
  1)
    if [ "${HARNESS_REQUIRE_TRACE:-0}" = "1" ]; then
      echo "[HARNESS POST] FAIL: Trace missing and HARNESS_REQUIRE_TRACE=1." >&2
      exit 1
    fi
    echo "[HARNESS POST] Trace: MISSING (advisory — set HARNESS_REQUIRE_TRACE=1 to block)." >&2
    ;;
  2) echo "[HARNESS POST] Trace: MALFORMED — review .agent-trace/ files." >&2 ;;
esac

# ── 2. Decision capture ───────────────────────────────────────────────────────
bash "$REPO_ROOT/harness/core/decision-capture.sh" || true

# ── 3. Pack validation (final) ────────────────────────────────────────────────
if [ -f "$REPO_ROOT/.harness/context-pack.json" ]; then
  bash "$REPO_ROOT/harness/core/pack-validate.sh" || true
fi

# ── 4. Summary ────────────────────────────────────────────────────────────────
echo "[HARNESS POST] Done. Pack=$HARNESS_PACK_ID  Trace=$HARNESS_TRACE_ID" >&2
echo "[HARNESS POST] Log files: .harness/" >&2

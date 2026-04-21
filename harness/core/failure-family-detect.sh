#!/usr/bin/env bash
# harness/core/failure-family-detect.sh
#
# Reference implementation: determine whether two error outputs belong to the
# same "failure family" for the purpose of repeated_failed_fix_loop detection.
#
# Adapters call this script to decide whether an attempt counts as a new
# failure or is still the same dominant failure family.
#
# Usage:
#   bash harness/core/failure-family-detect.sh <file-a> <file-b>
#
# Exit codes:
#   0 — same failure family (do NOT reset the attempt counter)
#   1 — different failure family (reset the attempt counter)
#   2 — one or both inputs are missing / empty (treat as unknown; do not reset)
#
# The script also prints a one-line human-readable verdict to stdout:
#   SAME_FAMILY   <family-label>   <matched-rule>
#   DIFF_FAMILY   <family-label-a> → <family-label-b>
#   UNKNOWN       (empty or missing input)
#
# Environment overrides:
#   FFDETECT_VERBOSE=1      — print detailed matching reasoning to stderr
#   FFDETECT_NORMALIZE=0    — disable line-number / address normalization
#                             (useful when comparing raw logs)
#
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

FILE_A="${1:-}"
FILE_B="${2:-}"

VERBOSE="${FFDETECT_VERBOSE:-0}"
NORMALIZE="${FFDETECT_NORMALIZE:-1}"

log() { [[ "$VERBOSE" == "1" ]] && echo "[ffdetect] $*" >&2 || true; }

# ── Validate inputs ───────────────────────────────────────────────────────────

if [[ -z "$FILE_A" || -z "$FILE_B" ]]; then
  echo "UNKNOWN (missing input)"
  exit 2
fi
if [[ ! -s "$FILE_A" || ! -s "$FILE_B" ]]; then
  echo "UNKNOWN (empty input)"
  exit 2
fi

# ── Normalize: strip noise that changes between runs but is not signal ─────────
# Line numbers, hex addresses, timestamps, and UUIDs often differ between
# identical failures — normalize them so family matching is stable.

normalize() {
  local text="$1"
  if [[ "$NORMALIZE" == "1" ]]; then
    echo "$text" \
      | sed 's/:[0-9]\{1,6\}:/:<LINE>:/g' \
      | sed 's/line [0-9]\+/line <N>/g' \
      | sed 's/0x[0-9a-fA-F]\{4,\}/<ADDR>/g' \
      | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9:\.Z+-]\{8,\}/<TS>/g' \
      | sed 's/[0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}/<UUID>/g'
  else
    echo "$text"
  fi
}

TEXT_A="$(normalize "$(cat "$FILE_A")")"
TEXT_B="$(normalize "$(cat "$FILE_B")")"

# ── Family classifiers ─────────────────────────────────────────────────────────
# Each classifier produces a short canonical label for a failure family.
# Add project-specific classifiers by extending the blocks below.

classify() {
  local text="$1"
  local label="unknown"

  # ── Test / assertion failures ──────────────────────────────────────────────
  if echo "$text" | grep -qEi 'assert(ionerror|_fail|ion failed|ed:)|expected.*got|FAIL\b|FAILED\b|failing test'; then
    # Try to extract the test name / function for tighter grouping
    local test_name
    test_name="$(echo "$text" | grep -Eoi '(FAIL|FAILED)\s+\S+' | head -1 | awk '{print $2}')"
    if [[ -n "$test_name" ]]; then
      label="test_failure:${test_name}"
    else
      label="test_failure"
    fi

  # ── Lint / static analysis ─────────────────────────────────────────────────
  elif echo "$text" | grep -qEi 'lint|eslint|pylint|tslint|golangci|mypy|typecheck|type error'; then
    local rule
    rule="$(echo "$text" | grep -Eoi '[A-Z][A-Z0-9-]+[0-9]{2,}' | sort | uniq | head -1)"
    if [[ -n "$rule" ]]; then
      label="lint:${rule}"
    else
      label="lint"
    fi

  # ── Build / compile errors ─────────────────────────────────────────────────
  elif echo "$text" | grep -qEi 'syntax error|compile error|build fail|cannot find module|import.*not found|undefined.*symbol|undeclared'; then
    local symbol
    symbol="$(echo "$text" | grep -Eoi "(cannot find|undefined|undeclared)[^:'\n]{0,40}" | head -1 | sed 's/^ *//')"
    if [[ -n "$symbol" ]]; then
      label="build_error:${symbol:0:60}"
    else
      label="build_error"
    fi

  # ── Runtime exceptions ─────────────────────────────────────────────────────
  elif echo "$text" | grep -qEi '(exception|error|panic|fatal)[^:]*:'; then
    # Extract exception class or panic message
    local exc
    exc="$(echo "$text" | grep -Eoi '([A-Z][a-zA-Z]+Exception|[A-Z][a-zA-Z]*Error|panic:)[^:\n]{0,50}' | head -1 | sed 's/:[[:space:]]*//')"
    if [[ -n "$exc" ]]; then
      label="exception:${exc:0:60}"
    else
      label="exception"
    fi

  # ── Schema / migration errors ──────────────────────────────────────────────
  elif echo "$text" | grep -qEi 'schema|migration|column.*does not exist|table.*not found|constraint violation'; then
    label="schema_error"

  # ── Auth / permission errors ───────────────────────────────────────────────
  elif echo "$text" | grep -qEi '401|403|unauthorized|forbidden|permission denied|access denied'; then
    label="auth_error"

  # ── Network / infra ────────────────────────────────────────────────────────
  elif echo "$text" | grep -qEi 'connection refused|timeout|ECONNREFUSED|ETIMEDOUT|network.*error|no such host'; then
    label="infra_error"
  fi

  echo "$label"
}

FAMILY_A="$(classify "$TEXT_A")"
FAMILY_B="$(classify "$TEXT_B")"

log "family A: $FAMILY_A"
log "family B: $FAMILY_B"

# ── Decision ───────────────────────────────────────────────────────────────────
#
# Two failures are "same family" when:
#   1. Their top-level classifier label matches exactly (test_failure, lint, etc.)
#   2. OR both are "unknown" (we cannot determine the family — treat conservatively as same)
#
# They are "different family" when:
#   3. Their classifier labels are different AND neither is "unknown"

get_top_level() {
  echo "${1%%:*}"
}

TOP_A="$(get_top_level "$FAMILY_A")"
TOP_B="$(get_top_level "$FAMILY_B")"

if [[ "$FAMILY_A" == "unknown" && "$FAMILY_B" == "unknown" ]]; then
  echo "UNKNOWN (could not classify either input)"
  exit 2
fi

if [[ "$TOP_A" == "$TOP_B" ]]; then
  echo "SAME_FAMILY   ${TOP_A}   (exact-label match)"
  exit 0
fi

echo "DIFF_FAMILY   ${TOP_A} → ${TOP_B}"
exit 1

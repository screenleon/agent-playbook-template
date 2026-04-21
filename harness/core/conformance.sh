#!/usr/bin/env bash
# harness/core/conformance.sh — Unified adapter conformance checker.
# ─────────────────────────────────────────────────────────────────────────────
# Verifies the active adapter environment can read the three required fields
# from prompt-budget.yml (execution_mode, budget.profile, model_routing.enabled)
# and that adapter-specific required files are present and correct.
#
# Usage:
#   bash harness/core/conformance.sh [--adapter <name>]
#
# Supported adapters: claude-code, copilot, cursor, opencode, windsurf, generic
# If --adapter is omitted, the adapter is auto-detected via detect-tool.sh.
# Override via env: HARNESS_TOOL=cursor bash harness/core/conformance.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUDGET_FILE="${BUDGET_FILE:-$ROOT_DIR/prompt-budget.yml}"

# ── Parse arguments ──────────────────────────────────────────────────────────

ADAPTER="${HARNESS_TOOL:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --adapter) ADAPTER="$2"; shift 2 ;;
    *) printf 'Unknown flag: %s\n' "$1" >&2; exit 1 ;;
  esac
done

# Auto-detect if not specified
if [[ -z "$ADAPTER" ]]; then
  ADAPTER="$(bash "$ROOT_DIR/harness/detect-tool.sh" 2>/dev/null)" || ADAPTER="generic"
fi

pass_count=0
fail_count=0

# ── Helpers ──────────────────────────────────────────────────────────────────

check() {
  local label="$1"
  local value="$2"
  local expected_pattern="$3"   # empty string = only check non-empty

  if [[ -z "$value" ]]; then
    printf 'FAIL  %s — field is missing or empty\n' "$label"
    (( fail_count++ )) || true
    return
  fi

  if [[ -n "$expected_pattern" && ! "$value" =~ $expected_pattern ]]; then
    printf 'FAIL  %s — value "%s" does not match pattern "%s"\n' "$label" "$value" "$expected_pattern"
    (( fail_count++ )) || true
    return
  fi

  printf 'PASS  %s = "%s"\n' "$label" "$value"
  (( pass_count++ )) || true
}

# Check an adapter-specific file for presence and optionally content.
# $1 = repo-relative path   $2 = "true" (default) to also grep for execution_mode
check_adapter_file() {
  local rel_path="$1"
  local check_content="${2:-true}"
  local file_name
  file_name="$(basename "$rel_path")"
  local full_path="$ROOT_DIR/$rel_path"

  if [[ -f "$full_path" ]]; then
    if [[ "$check_content" == "true" ]]; then
      if grep -q "execution_mode" "$full_path"; then
        printf 'PASS  %s references execution_mode\n' "$file_name"
        (( pass_count++ )) || true
      else
        printf 'FAIL  %s does not reference execution_mode\n' "$file_name"
        (( fail_count++ )) || true
      fi
    else
      printf 'PASS  %s is present\n' "$file_name"
      (( pass_count++ )) || true
    fi
  else
    printf 'FAIL  %s not found (required for %s adapter)\n' "$file_name" "$ADAPTER"
    (( fail_count++ )) || true
  fi
}

# ── Field extraction (plain awk — no yq dependency) ──────────────────────────

read_scalar() {
  local key="$1"
  awk -v key="$key" '
    $0 ~ ("^" key ":[[:space:]]*") {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*$/, "", $0)   # strip inline comment
      gsub(/^["\x27]|["\x27]$/, "", $0)
      print $0
      exit
    }
  ' "$BUDGET_FILE"
}

read_model_routing_enabled() {
  awk '
    /^model_routing:/ { in_block=1; next }
    in_block && /^[^[:space:]]/ { in_block=0 }
    in_block && /^[[:space:]]+enabled:/ {
      sub(/.*enabled:[[:space:]]*/, "", $0)
      gsub(/^["\x27]|["\x27]$/, "", $0)
      print $0
      exit
    }
  ' "$BUDGET_FILE"
}

read_budget_profile() {
  awk '
    /^budget:/ { in_block=1; next }
    in_block && /^[^[:space:]]/ { in_block=0 }
    in_block && /^[[:space:]]+profile:/ {
      sub(/.*profile:[[:space:]]*/, "", $0)
      gsub(/^["\x27]|["\x27]$/, "", $0)
      print $0
      exit
    }
  ' "$BUDGET_FILE"
}

# ── Checks ───────────────────────────────────────────────────────────────────

printf '=== %s adapter conformance ===\n' "$ADAPTER"
printf 'budget_file: %s\n\n' "$BUDGET_FILE"

if [[ ! -f "$BUDGET_FILE" ]]; then
  printf 'ERROR  prompt-budget.yml not found at %s\n' "$BUDGET_FILE"
  exit 2
fi

execution_mode="$(read_scalar execution_mode)"
check "execution_mode" "$execution_mode" "^(supervised|semi-auto|autonomous)$"

budget_profile="$(read_budget_profile)"
check "budget.profile" "$budget_profile" "^(nano|minimal|standard|full)$"

model_routing_enabled="$(read_model_routing_enabled)"
check "model_routing.enabled" "$model_routing_enabled" "^(true|false)$"

# ── Adapter-specific required files ──────────────────────────────────────────

case "$ADAPTER" in
  copilot)
    check_adapter_file "harness/adapters/copilot/governance-block.md"
    ;;
  cursor)
    check_adapter_file "harness/adapters/cursor/harness.mdc"
    ;;
  opencode)
    check_adapter_file "harness/adapters/opencode/harness.md"
    ;;
  windsurf)
    check_adapter_file "harness/adapters/windsurf/harness-rules.md"
    ;;
  generic)
    # Hook scripts: check presence only (no execution_mode content requirement)
    check_adapter_file "harness/adapters/generic/pre-invoke.sh"  "false"
    check_adapter_file "harness/adapters/generic/post-invoke.sh" "false"
    ;;
  claude-code|*)
    # claude-code: no extra required file beyond ADAPTER.md below
    ;;
esac

# ── ADAPTER.md references execution_mode (all adapters) ─────────────────────

adapter_doc="$ROOT_DIR/harness/adapters/$ADAPTER/ADAPTER.md"
if [[ -f "$adapter_doc" ]]; then
  if grep -q "execution_mode" "$adapter_doc"; then
    printf 'PASS  ADAPTER.md references execution_mode\n'
    (( pass_count++ )) || true
  else
    printf 'FAIL  ADAPTER.md does not reference execution_mode\n'
    (( fail_count++ )) || true
  fi
else
  printf 'WARN  ADAPTER.md not found (skipping doc check)\n'
fi

# ── Summary ──────────────────────────────────────────────────────────────────

printf '\n--- Results: %s passed, %s failed ---\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1

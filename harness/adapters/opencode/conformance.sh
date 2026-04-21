#!/usr/bin/env bash
# harness/adapters/opencode/conformance.sh
# ─────────────────────────────────────────────────────────────────────────────
# Conformance check for the opencode adapter.
# Verifies the adapter environment can read the three required fields from
# prompt-budget.yml: execution_mode, budget.profile, and model_routing.enabled.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BUDGET_FILE="${BUDGET_FILE:-$ROOT_DIR/prompt-budget.yml}"

pass_count=0
fail_count=0

check() {
  local label="$1"
  local value="$2"
  local expected_pattern="$3"

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

read_scalar() {
  local key="$1"
  awk -v key="$key" '
    $0 ~ ("^" key ":[[:space:]]*") {
      sub("^[^:]+:[[:space:]]*", "", $0)
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

printf '=== opencode adapter conformance ===\n'
printf 'budget_file: %s\n\n' "$BUDGET_FILE"

if [[ ! -f "$BUDGET_FILE" ]]; then
  printf 'ERROR  prompt-budget.yml not found at %s\n' "$BUDGET_FILE"
  exit 2
fi

execution_mode="$(read_scalar execution_mode)"
check "execution_mode" "$execution_mode" "^(supervised|semi-auto|autonomous)$"

budget_profile="$(read_scalar profile)"
check "budget.profile" "$budget_profile" "^(nano|minimal|standard|full)$"

model_routing_enabled="$(read_model_routing_enabled)"
check "model_routing.enabled" "$model_routing_enabled" "^(true|false)$"

# opencode-specific: harness.md must be present
harness_md="$ROOT_DIR/harness/adapters/opencode/harness.md"
if [[ -f "$harness_md" ]]; then
  if grep -q "execution_mode" "$harness_md"; then
    printf 'PASS  harness.md references execution_mode\n'
    (( pass_count++ )) || true
  else
    printf 'FAIL  harness.md does not reference execution_mode\n'
    (( fail_count++ )) || true
  fi
else
  printf 'FAIL  harness.md not found (required for opencode adapter)\n'
  (( fail_count++ )) || true
fi

adapter_doc="$ROOT_DIR/harness/adapters/opencode/ADAPTER.md"
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

printf '\n--- Results: %s passed, %s failed ---\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1

#!/usr/bin/env bash
# test.sh — Smoke tests for harness internal consistency.
#
# Run after any harness change to verify:
#   1. All adapters referenced by detect-tool.sh and install.sh exist
#   2. bootstrap.sh parses prompt-budget.yml correctly
#   3. gate-check.sh blocks/approves the expected operations
#   4. core scripts are executable
#
# Usage:
#   bash harness/test.sh
#
# Exit code: 0 = all pass, 1 = one or more failures

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PASS=0
FAIL=0

_pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
_fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
_section() { echo ""; echo "── $1 ──────────────────────────────"; }

# ── 1. Adapter completeness ───────────────────────────────────────────────────
_section "Adapter completeness"

# Every tool that detect-tool.sh can return must have an adapter directory
DETECTABLE_TOOLS="claude-code copilot cursor windsurf opencode"
for tool in $DETECTABLE_TOOLS; do
  if [ -d "$REPO_ROOT/harness/adapters/$tool" ]; then
    _pass "Adapter directory exists: harness/adapters/$tool/"
  else
    _fail "Missing adapter directory: harness/adapters/$tool/"
  fi
done

# Every tool must have an ADAPTER.md
for tool in $DETECTABLE_TOOLS generic; do
  if [ -f "$REPO_ROOT/harness/adapters/$tool/ADAPTER.md" ]; then
    _pass "ADAPTER.md exists: $tool"
  else
    _fail "Missing ADAPTER.md: harness/adapters/$tool/ADAPTER.md"
  fi
done

# ── 2. Core scripts are executable ───────────────────────────────────────────
_section "Script executability"

for script in bootstrap.sh detect-tool.sh install.sh test.sh \
    core/gate-check.sh core/trace-validate.sh core/pack-validate.sh core/decision-capture.sh \
    adapters/generic/pre-invoke.sh adapters/generic/post-invoke.sh; do
  path="$REPO_ROOT/harness/$script"
  if [ -x "$path" ]; then
    _pass "Executable: harness/$script"
  else
    _fail "Not executable: harness/$script"
  fi
done

# ── 3. Bootstrap parsing ──────────────────────────────────────────────────────
_section "Bootstrap parsing"

BOOTSTRAP_OUT=$(bash "$REPO_ROOT/harness/bootstrap.sh" 2>/dev/null)
eval "$BOOTSTRAP_OUT" 2>/dev/null

[ -n "${HARNESS_EXECUTION_MODE:-}" ] && _pass "HARNESS_EXECUTION_MODE set: $HARNESS_EXECUTION_MODE" || _fail "HARNESS_EXECUTION_MODE empty"
[ -n "${HARNESS_BUDGET_PROFILE:-}" ] && _pass "HARNESS_BUDGET_PROFILE set: $HARNESS_BUDGET_PROFILE" || _fail "HARNESS_BUDGET_PROFILE empty"
[ -n "${HARNESS_PACK_ID:-}" ]        && _pass "HARNESS_PACK_ID set" || _fail "HARNESS_PACK_ID empty"
[ -n "${HARNESS_TRACE_ID:-}" ]       && _pass "HARNESS_TRACE_ID set" || _fail "HARNESS_TRACE_ID empty"
[ -n "${HARNESS_LAYER1_FILES:-}" ]   && _pass "HARNESS_LAYER1_FILES set" || _fail "HARNESS_LAYER1_FILES empty"

# ── 4. gate-check patterns ────────────────────────────────────────────────────
_section "Gate-check: always-dangerous operations"

_gate_should_block() {
  local tool="$1" input="$2"
  result=$(bash "$REPO_ROOT/harness/core/gate-check.sh" "$tool" "$input" 2>/dev/null || true)
  if echo "$result" | grep -q '"block"'; then
    _pass "Blocked: $tool '$input'"
  else
    _fail "Should have blocked: $tool '$input'"
  fi
}

_gate_should_approve() {
  local tool="$1" input="$2"
  result=$(bash "$REPO_ROOT/harness/core/gate-check.sh" "$tool" "$input" 2>/dev/null || true)
  if echo "$result" | grep -q '"approve"'; then
    _pass "Approved: $tool '$input'"
  else
    _fail "Should have approved: $tool '$input'"
  fi
}

_gate_should_block "Bash" "git push --force origin main"
_gate_should_block "Bash" "git reset --hard HEAD~3"
_gate_should_block "Bash" "rm -rf ./dist/"
_gate_should_block "Bash" "DROP TABLE users;"
_gate_should_block "Bash" "git push origin main"
_gate_should_block "Write" ".github/workflows/ci.yml"

_gate_should_approve "Bash" "git status"
_gate_should_approve "Bash" "git log --oneline"
_gate_should_approve "Bash" "npm test"
_gate_should_approve "Bash" "rm -f temp.txt"
_gate_should_approve "Write" "src/components/Button.tsx"

# ── 5. Template files exist ───────────────────────────────────────────────────
_section "Adapter template files"

[ -f "$REPO_ROOT/harness/adapters/claude-code/settings.hooks.json" ] && _pass "claude-code: settings.hooks.json" || _fail "Missing settings.hooks.json"
[ -f "$REPO_ROOT/harness/adapters/copilot/governance-block.md" ]     && _pass "copilot: governance-block.md" || _fail "Missing governance-block.md"
[ -f "$REPO_ROOT/harness/adapters/cursor/harness.mdc" ]              && _pass "cursor: harness.mdc" || _fail "Missing harness.mdc"
[ -f "$REPO_ROOT/harness/adapters/windsurf/harness-rules.md" ]       && _pass "windsurf: harness-rules.md" || _fail "Missing harness-rules.md"
[ -f "$REPO_ROOT/harness/adapters/opencode/harness.md" ]             && _pass "opencode: harness.md" || _fail "Missing harness.md"

# ── JSON validity ─────────────────────────────────────────────────────────────
_section "JSON validity"

if command -v python3 &>/dev/null; then
  python3 -c "import json; json.load(open('$REPO_ROOT/harness/adapters/claude-code/settings.hooks.json'))" 2>/dev/null \
    && _pass "settings.hooks.json is valid JSON" \
    || _fail "settings.hooks.json is invalid JSON"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $PASS passed, $FAIL failed"

[ $FAIL -eq 0 ] && echo "All tests passed." && exit 0 || exit 1

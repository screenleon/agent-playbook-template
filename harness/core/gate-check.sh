#!/usr/bin/env bash
# gate-check.sh — Evaluate checkpoint gates against always-dangerous operation patterns.
#
# Dual-mode:
#   Claude Code PreToolUse hook — reads JSON from stdin, outputs decision JSON to stdout.
#   Direct CLI call            — pass tool name and command as arguments.
#
# Exit codes (meaningful in both modes):
#   0  PASS    — operation allowed
#   1  STOP    — operation blocked; reason printed to stderr
#   2  ADVISORY — warning issued but operation allowed to proceed
#
# Claude Code hook usage (wired via settings.json):
#   stdin: {"tool_name":"Bash","tool_input":{"command":"git push --force"}}
#   stdout: {"decision":"block","reason":"..."} or {"decision":"approve"}
#
# Direct usage:
#   bash harness/core/gate-check.sh Bash "git push --force"
#   bash harness/core/gate-check.sh Write "/etc/hosts"

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ── Always-dangerous patterns (from docs/operating-rules.md) ─────────────────
# Each entry is an ERE pattern matched against "<tool_name> <tool_input>"
DANGEROUS_PATTERNS=(
  "git[[:space:]]+push[[:space:]]+.*--force"
  "git[[:space:]]+reset[[:space:]]+.*--hard"
  "git[[:space:]]+checkout[[:space:]]+--[[:space:]]"  # git checkout -- <file> (discard only; -b/-t branch ops are always-safe per operating-rules)
  "git[[:space:]]+branch[[:space:]]+-[Dd]"
  "rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*[[:space:]]"        # rm with -r flag (rm -r, rm -rf, rm -Rf)
  "DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)"
  "TRUNCATE[[:space:]]+TABLE"
  "DELETE[[:space:]]+FROM[[:space:]]+[^[:space:]]+[[:space:]]*;"  # bare DELETE without WHERE
  "git[[:space:]]+push[[:space:]]+[^-][^[:space:]]*[[:space:]]+(main|master|production|prod)"
  "npm[[:space:]]+publish"
  "yarn[[:space:]]+publish"
  "gh[[:space:]]+release[[:space:]]+create"
)

# Files / path patterns that are always-dangerous to write
DANGEROUS_PATHS=(
  "\.github/workflows/"
  "\.github/actions/"
  "Dockerfile"
  "docker-compose"
  "\.terraform"
  "infra/"
  "deploy/"
  "/etc/"
)

# ── Read execution mode ───────────────────────────────────────────────────────
_get_execution_mode() {
  if [ -n "${HARNESS_EXECUTION_MODE:-}" ]; then
    echo "$HARNESS_EXECUTION_MODE"
    return
  fi
  if command -v python3 &>/dev/null && [ -f "$REPO_ROOT/prompt-budget.yml" ]; then
    python3 - "$REPO_ROOT/prompt-budget.yml" 2>/dev/null <<'PYEOF' || echo "semi-auto"
import re, sys
with open(sys.argv[1]) as f:
    content = f.read()
m = re.search(r'^execution_mode:\s*([^\n#]+)', content, re.MULTILINE)
print(m.group(1).strip().strip('"\'') if m else 'semi-auto')
PYEOF
  else
    echo "semi-auto"
  fi
}

_get_halt_destructive() {
  if [ -n "${HARNESS_HALT_DESTRUCTIVE:-}" ]; then
    echo "$HARNESS_HALT_DESTRUCTIVE"
    return
  fi
  # Default: true (halt on destructive actions)
  echo "true"
}

# ── Pattern matching ──────────────────────────────────────────────────────────
_is_dangerous_command() {
  local subject="$1"
  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$subject" | grep -qE "$pattern" 2>/dev/null; then
      echo "$pattern"
      return 0
    fi
  done
  return 1
}

_is_dangerous_path() {
  local path="$1"
  for pattern in "${DANGEROUS_PATHS[@]}"; do
    if echo "$path" | grep -qE "$pattern" 2>/dev/null; then
      echo "$pattern"
      return 0
    fi
  done
  return 1
}

# ── Decision logic ────────────────────────────────────────────────────────────
_decide() {
  local tool_name="$1"
  local tool_input="$2"
  local subject="$tool_name $tool_input"

  local matched_pattern
  local mode halt_destructive

  mode=$(_get_execution_mode)
  halt_destructive=$(_get_halt_destructive)

  # Check command patterns
  if matched_pattern=$(_is_dangerous_command "$subject" 2>/dev/null); then
    _enforce "$tool_name" "$tool_input" "$matched_pattern" "$mode" "$halt_destructive"
    return
  fi

  # Check dangerous write/edit paths
  if [[ "$tool_name" =~ ^(Write|Edit)$ ]]; then
    if matched_pattern=$(_is_dangerous_path "$tool_input" 2>/dev/null); then
      _enforce "$tool_name" "$tool_input" "dangerous path: $matched_pattern" "$mode" "$halt_destructive"
      return
    fi
  fi

  # PASS
  echo '{"decision":"approve"}'
  exit 0
}

_enforce() {
  local tool="$1" input="$2" pattern="$3" mode="$4" halt="$5"
  local reason="Matched always-dangerous pattern: $pattern. Tool=$tool, Input=$input."

  case "$mode" in
    supervised|semi-auto)
      # Always stop for human approval
      echo "{\"decision\":\"block\",\"reason\":\"[HARNESS GATE] $reason Execution mode '$mode' requires human approval for this operation.\"}"
      echo "[HARNESS GATE STOP] $reason" >&2
      exit 1
      ;;
    autonomous)
      if [ "$halt" = "true" ]; then
        echo "{\"decision\":\"block\",\"reason\":\"[HARNESS GATE] $reason autonomous_mode.halt_on_destructive_actions=true.\"}"
        echo "[HARNESS GATE STOP] $reason" >&2
        exit 1
      else
        # Advisory — log but allow
        echo "{\"decision\":\"approve\"}"
        echo "[HARNESS ADVISORY] $reason halt_on_destructive_actions=false — proceeding." >&2
        exit 2
      fi
      ;;
    *)
      # Unknown mode — default to block
      echo "{\"decision\":\"block\",\"reason\":\"[HARNESS GATE] Unknown execution mode '$mode'. Blocking as safe default.\"}"
      exit 1
      ;;
  esac
}

# ── Entry point ───────────────────────────────────────────────────────────────
if [ -t 0 ] || [ $# -ge 1 ]; then
  # Direct CLI invocation: gate-check.sh <tool_name> [<input>]
  TOOL_NAME="${1:-Bash}"
  TOOL_INPUT="${2:-}"
  _decide "$TOOL_NAME" "$TOOL_INPUT"
else
  # Claude Code hook mode: JSON on stdin
  if ! command -v python3 &>/dev/null; then
    echo '{"decision":"approve"}' # can't parse — let tool decide
    exit 0
  fi
  INPUT=$(cat)
  TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")
  TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
tool_name = d.get('tool_name', '')
ti = d.get('tool_input', {})
# Extract the most searchable string from tool_input:
# - Bash/Shell: use 'command' field directly (the actual shell command)
# - Write/Edit: use 'file_path' field for path matching
# - Other: flatten to JSON
if isinstance(ti, dict):
    if tool_name in ('Bash',) and 'command' in ti:
        print(ti['command'])
    elif tool_name in ('Write', 'Edit') and 'file_path' in ti:
        print(ti.get('file_path', '') + ' ' + ti.get('new_string', '')[:200])
    else:
        print(' '.join(str(v) for v in ti.values() if isinstance(v, str)))
else:
    print(str(ti))
" 2>/dev/null || echo "")
  _decide "$TOOL_NAME" "$TOOL_INPUT"
fi

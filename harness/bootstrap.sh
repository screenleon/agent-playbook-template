#!/usr/bin/env bash
# bootstrap.sh — Read prompt-budget.yml and export harness environment variables.
#
# Usage:
#   eval "$(bash harness/bootstrap.sh)"          # export vars into current shell
#   source <(bash harness/bootstrap.sh)           # equivalent
#   HARNESS_WRITE_PACK=1 bash harness/bootstrap.sh  # also write .harness/context-pack.json
#
# Required env vars for pack assembly (optional — defaults are applied):
#   HARNESS_OBJECTIVE, HARNESS_ROLE, HARNESS_INTENT_MODE, HARNESS_TASK_SCALE
#   HARNESS_SCOPE_SUMMARY
#
# Exported variables:
#   HARNESS_TOOL              detected tool (or HARNESS_TOOL override)
#   HARNESS_EXECUTION_MODE    supervised | semi-auto | autonomous
#   HARNESS_BUDGET_PROFILE    nano | minimal | standard | full
#   HARNESS_DECISION_POLICY   example_only | normal
#   HARNESS_ENABLED_ROLES     space-separated list
#   HARNESS_ALWAYS_LOAD_SKILLS space-separated list
#   HARNESS_LAYER1_FILES      space-separated doc paths to load
#   HARNESS_PACK_ID           unique pack identifier
#   HARNESS_TRACE_ID          unique trace identifier
#   HARNESS_HALT_DESTRUCTIVE  true | false

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BUDGET_FILE="$REPO_ROOT/prompt-budget.yml"
HARNESS_DIR="$REPO_ROOT/.harness"

if [ ! -f "$BUDGET_FILE" ]; then
  echo "ERROR: prompt-budget.yml not found at $BUDGET_FILE" >&2
  exit 1
fi

# Parse prompt-budget.yml — prefers PyYAML, falls back to regex extraction
_parse() {
  python3 - <<PYEOF
import sys, json, os, re

config_path = "$BUDGET_FILE"

def grep_value(content, key, default=''):
    m = re.search(rf'^{re.escape(key)}:\s*([^\n#]+)', content, re.MULTILINE)
    return m.group(1).strip().strip('"\'') if m else default

def grep_nested_value(content, parent_key, child_key, default=''):
    """Extract a scalar nested under a parent block (e.g. budget.profile)."""
    in_block = False
    for line in content.splitlines():
        stripped = line.strip()
        if re.match(rf'^{re.escape(parent_key)}:\s*$', stripped):
            in_block = True
            continue
        if in_block:
            if stripped and re.match(r'^[A-Za-z_]', line):
                break  # back to top-level
            m = re.match(rf'^\s+{re.escape(child_key)}:\s*([^\n#]+)', line)
            if m:
                return m.group(1).strip().strip('\'"')
    return default

def grep_list(content, key):
    # Extract YAML sequence items under a given key
    m = re.search(rf'^{re.escape(key)}:\s*\n((?:[ \t]+-[^\n]+\n?)*)', content, re.MULTILINE)
    if not m:
        return []
    return [re.sub(r'^\s*-\s*', '', l).strip() for l in m.group(1).splitlines() if l.strip().startswith('-')]

def grep_nested_list(content, parent_key, child_key):
    """Extract a YAML list nested under a parent block (e.g. roles.enabled)."""
    in_block = False
    in_list = False
    items = []
    for line in content.splitlines():
        stripped = line.strip()
        if re.match(rf'^{re.escape(parent_key)}:\s*$', stripped):
            in_block = True
            continue
        if in_block:
            if stripped and re.match(r'^[A-Za-z_]', line):
                break  # back to top-level
            if re.match(rf'^\s+{re.escape(child_key)}:\s*$', stripped):
                in_list = True
                continue
            if in_list:
                if stripped.startswith('- '):
                    items.append(stripped[2:].strip().strip('\'"'))
                elif stripped and not stripped.startswith('#'):
                    in_list = False
    return items

try:
    import yaml
    with open(config_path) as f:
        c = yaml.safe_load(f) or {}
    out = {
        'execution_mode':   c.get('execution_mode', 'semi-auto'),
        'budget_profile':   (c.get('budget') or {}).get('profile', 'standard'),
        'decision_policy':  (c.get('decision_log') or {}).get('policy', 'normal'),
        'enabled_roles':    ' '.join((c.get('roles') or {}).get('enabled') or []),
        'always_load':      ' '.join((c.get('skills') or {}).get('always_load') or []),
        'halt_destructive': str((c.get('autonomous_mode') or {}).get('halt_on_destructive_actions', True)).lower(),
    }
except ImportError:
    with open(config_path) as f:
        content = f.read()
    out = {
        'execution_mode':   grep_value(content, 'execution_mode', 'semi-auto'),
        'budget_profile':   grep_nested_value(content, 'budget', 'profile', 'standard'),
        'decision_policy':  grep_nested_value(content, 'decision_log', 'policy', 'normal'),
        'enabled_roles':    ' '.join(grep_nested_list(content, 'roles', 'enabled')),
        'always_load':      ' '.join(grep_list(content, 'always_load')),
        'halt_destructive': 'true',
    }

print(json.dumps(out))
PYEOF
}

PARSED=$(_parse)

_field() {
  local value
  value=$(echo "$PARSED" | python3 -c "import sys,json; print(json.load(sys.stdin)['$1'])" 2>/dev/null) || {
    echo "[HARNESS] WARNING: Failed to parse '$1' from prompt-budget.yml — using default." >&2
    return 1
  }
  echo "$value"
}

EXECUTION_MODE=$(_field execution_mode  2>/dev/null) || EXECUTION_MODE="semi-auto"
BUDGET_PROFILE=$(_field budget_profile  2>/dev/null) || BUDGET_PROFILE="standard"
DECISION_POLICY=$(_field decision_policy 2>/dev/null) || DECISION_POLICY="normal"
ENABLED_ROLES=$(_field enabled_roles    2>/dev/null) || ENABLED_ROLES=""
ALWAYS_LOAD=$(_field always_load        2>/dev/null) || ALWAYS_LOAD=""
HALT_DESTRUCTIVE=$(_field halt_destructive 2>/dev/null) || HALT_DESTRUCTIVE="true"

# Layer 1 files by budget profile
case "$BUDGET_PROFILE" in
  nano)    LAYER1_FILES="docs/rules-nano.md" ;;
  minimal) LAYER1_FILES="docs/rules-quickstart.md" ;;
  *)       LAYER1_FILES="docs/rules-quickstart.md docs/operating-rules.md docs/agent-playbook.md" ;;
esac

# Unique IDs
PACK_ID="ctx_$(date -u +%Y%m%d_%H%M%S)_$$"
TRACE_ID="trace_$(date -u +%Y%m%d_%H%M%S)_$$"
TOOL="$(bash "$REPO_ROOT/harness/detect-tool.sh" 2>/dev/null || echo generic)"

# Emit export statements so callers can eval or source
cat <<EXPORTS
export HARNESS_TOOL="$TOOL"
export HARNESS_EXECUTION_MODE="$EXECUTION_MODE"
export HARNESS_BUDGET_PROFILE="$BUDGET_PROFILE"
export HARNESS_DECISION_POLICY="$DECISION_POLICY"
export HARNESS_ENABLED_ROLES="$ENABLED_ROLES"
export HARNESS_ALWAYS_LOAD_SKILLS="$ALWAYS_LOAD"
export HARNESS_LAYER1_FILES="$LAYER1_FILES"
export HARNESS_PACK_ID="$PACK_ID"
export HARNESS_TRACE_ID="$TRACE_ID"
export HARNESS_HALT_DESTRUCTIVE="$HALT_DESTRUCTIVE"
EXPORTS

# Optionally write context-pack.json conforming to docs/schemas/context-pack.schema.json
if [ "${HARNESS_WRITE_PACK:-0}" = "1" ]; then
  mkdir -p "$HARNESS_DIR"
  PACK_FILE="$HARNESS_DIR/context-pack.json"
  OBJECTIVE="${HARNESS_OBJECTIVE:-Assembled by harness bootstrap}"
  ROLE="${HARNESS_ROLE:-application-implementer}"
  INTENT_MODE="${HARNESS_INTENT_MODE:-implement}"
  TASK_SCALE="${HARNESS_TASK_SCALE:-Small}"
  SCOPE_SUMMARY="${HARNESS_SCOPE_SUMMARY:-Full repository scope}"

  python3 - <<PYEOF
import json
from datetime import datetime, timezone

pack = {
    "schema_version": "1.0.0",
    "pack_id": "$PACK_ID",
    "generated_at": datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    "objective": "$OBJECTIVE",
    "role": "$ROLE",
    "intent_mode": "$INTENT_MODE",
    "task_scale": "$TASK_SCALE",
    "execution_mode": "$EXECUTION_MODE",
    "budget_profile": "$BUDGET_PROFILE",
    "approved_scope": {
        "summary": "$SCOPE_SUMMARY",
        "allowed_paths": [],
        "non_goals": [],
        "acceptance_criteria": []
    },
    "constraints": [
        "Follow AGENTS.md",
        "Do not expand scope without approval"
    ],
    "source_of_truth": {
        "entrypoint_refs": ["AGENTS.md"],
        "rules_refs":      ["docs/operating-rules.md"],
        "playbook_refs":   ["docs/agent-playbook.md"],
        "decision_refs":   ["DECISIONS.md"]
    },
    "artifacts": {
        "context_files":   [],
        "critical_context": []
    },
    "expected_output": {
        "format":              "summary",
        "success_definition":  "Task completed with validation passing.",
        "validation_required": True
    },
    "audit": {
        "source_marker": "[harness:bootstrap]",
        "trace_id":      "$TRACE_ID",
        "generated_by":  "harness/bootstrap.sh"
    }
}
with open("$PACK_FILE", "w") as f:
    json.dump(pack, f, indent=2)
import sys
print(f"Pack written to $PACK_FILE", file=sys.stderr)
PYEOF
fi

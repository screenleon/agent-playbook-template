#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="strict"
EXIT_CODE=0

for arg in "$@"; do
  case "$arg" in
    --strict)
      MODE="strict"
      ;;
    --template-mode)
      MODE="template"
      ;;
    *)
      echo "[adoption-audit][error] unknown argument: $arg"
      exit 2
      ;;
  esac
done

report_issue() {
  local message="$1"

  if [[ "$MODE" == "template" ]]; then
    echo "[adoption-audit][warn] $message"
  else
    echo "[adoption-audit][error] $message"
    EXIT_CODE=1
  fi
}

echo "[adoption-audit] mode=$MODE"

if [[ -f "$ROOT_DIR/project/project-manifest.md" ]]; then
  blank_fields="$(grep -cE '^- [^:]+:[[:space:]]*$' "$ROOT_DIR/project/project-manifest.md" || true)"
  blank_rows="$(grep -cE '^\|[[:space:]]*\|[[:space:]]*\|[[:space:]]*\|([[:space:]]*\|)?([[:space:]]*active[[:space:]]*\|)?$' "$ROOT_DIR/project/project-manifest.md" || true)"

  if [[ "$blank_fields" -gt 0 ]]; then
    report_issue "project/project-manifest.md still has blank fields ($blank_fields)"
  fi

  if [[ "$blank_rows" -gt 0 ]]; then
    report_issue "project/project-manifest.md still has placeholder table rows ($blank_rows)"
  fi
fi

if grep -Fq 'Source of truth: `project/project-manifest.md`.' "$ROOT_DIR/docs/operating-rules.md"; then
  :
elif grep -Eq '^## Project-specific constraints$' "$ROOT_DIR/docs/operating-rules.md"; then
  report_issue 'docs/operating-rules.md project-specific constraints section is not aligned to the manifest source-of-truth pattern'
fi

if [[ -f "$ROOT_DIR/DECISIONS.md" ]] && ! grep -Eq '^## [0-9]{4}-[0-9]{2}-[0-9]{2}:' "$ROOT_DIR/DECISIONS.md"; then
  report_issue 'DECISIONS.md has no real decision entries yet'
fi

if grep -Fq '> **Adopter note**: This file documents the template repository itself.' "$ROOT_DIR/ARCHITECTURE.md"; then
  report_issue 'ARCHITECTURE.md still describes the template repository'
fi

if [[ -f "$ROOT_DIR/.github/workflows/agent-review.yml" && ! -f "$ROOT_DIR/scripts/agent-review.sh" ]]; then
  report_issue 'agent-review workflow exists but scripts/agent-review.sh is missing'
fi

# Check prompt-budget.yml existence and basic validity.
if [[ ! -f "$ROOT_DIR/prompt-budget.yml" ]]; then
  report_issue 'prompt-budget.yml is missing (required by AGENTS.md loading logic)'
else
  if ! grep -Eq '^execution_mode:[[:space:]]*(supervised|semi-auto|autonomous)' "$ROOT_DIR/prompt-budget.yml"; then
    report_issue 'prompt-budget.yml execution_mode is missing or invalid (expected supervised|semi-auto|autonomous)'
  fi
  if ! grep -Eq '^[[:space:]]*profile:[[:space:]]*(nano|minimal|standard|full)' "$ROOT_DIR/prompt-budget.yml"; then
    report_issue 'prompt-budget.yml budget.profile is missing or invalid (expected nano|minimal|standard|full)'
  fi
fi

# Check required doc files exist.
for required_doc in "docs/rules-nano.md" "docs/rules-quickstart.md" "docs/operating-rules.md" "docs/agent-playbook.md"; do
  if [[ ! -f "$ROOT_DIR/$required_doc" ]]; then
    report_issue "$required_doc is missing (required by AGENTS.md loading logic)"
  fi
done

if [[ $EXIT_CODE -ne 0 ]]; then
  echo '[adoption-audit] failed'
else
  echo '[adoption-audit] passed'
fi

exit $EXIT_CODE

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXIT_CODE=0

echo "[doc-lint] checking prompt-budget and docs consistency..."

check_grep() {
  local description="$1"
  local pattern="$2"
  shift 2
  local output
  output=$(rg -n "$pattern" "$@" || true)
  if [[ -n "$output" ]]; then
    echo "[doc-lint][error] ${description}"
    echo "$output"
    EXIT_CODE=1
  fi
}

# Disallow stale profile wording.
check_grep \
  "stale three-profile wording found" \
  "three named budget profiles|three profile example blocks" \
  "$ROOT_DIR/CHANGELOG.md" "$ROOT_DIR/README.md" "$ROOT_DIR/docs" "$ROOT_DIR/examples" "$ROOT_DIR/skills"

# Disallow stale top-level trust_level config examples on config-like surfaces.
check_grep \
  "stale top-level trust_level config found" \
  "^[[:space:]]*trust_level:" \
  "$ROOT_DIR/docs/adoption-guide.md" "$ROOT_DIR/docs/prompt-budget-examples.md" "$ROOT_DIR/examples" "$ROOT_DIR/skills/prompt-cache-optimization/SKILL.md"

# Non-autonomous config examples should not define autonomous_mode.
mapfile -t non_autonomous_files < <(rg -l "^[[:space:]]*execution_mode:[[:space:]]*(supervised|semi-auto)" \
  "$ROOT_DIR/examples" "$ROOT_DIR/skills/prompt-cache-optimization/SKILL.md" || true)
for file in "${non_autonomous_files[@]}"; do
  if rg -n "^[[:space:]]*autonomous_mode:" "$file" >/dev/null 2>&1; then
    echo "[doc-lint][error] non-autonomous example defines autonomous_mode: ${file#$ROOT_DIR/}"
    rg -n "^[[:space:]]*(execution_mode:|autonomous_mode:)" "$file" || true
    EXIT_CODE=1
  fi
done

# Canonical prompt-budget keys should be used in examples/docs.
check_grep \
  "stale prompt-budget key found" \
  "require_risk_reviewer_for_all_changes|require_adr_for_architecture_change|block_destructive_actions_without_manual_approval|small_tasks_skip_compliance_block|targeted_tests_for_small_tasks|critic_required_only_for_large_changes|prefer_existing_code_practice|require_explicit_approval_for_pattern_replacement|legacy_modules_require_archive_decision_search" \
  "$ROOT_DIR/README.md" "$ROOT_DIR/docs" "$ROOT_DIR/examples" "$ROOT_DIR/skills"

# `prompt-budget.yml` is not the example gallery file anymore.
check_grep \
  "stale prompt-budget example reference found" \
  'prompt-budget\.yml` for example configurations per profile' \
  "$ROOT_DIR/README.md" "$ROOT_DIR/docs" "$ROOT_DIR/skills"

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "[doc-lint] failed"
else
  echo "[doc-lint] passed"
fi

exit $EXIT_CODE

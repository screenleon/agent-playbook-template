#!/usr/bin/env bash
# run-evals.sh — Adapter-neutral eval runner.
#
# For each eval fixture under evals/tasks/, this script:
#   1. Invokes the configured agent runtime with the task.md prompt.
#   2. Collects the trace file the runtime produced.
#   3. Calls scripts/score-eval.py to compare the trace against
#      expected-behavior.yaml.
#   4. Aggregates per-eval PASS/FAIL into a summary + exit code.
#
# The script does NOT hardcode any adapter. Adapter integration happens via
# the AGENT_INVOKE environment variable, a shell command that:
#   - Receives the task.md path as $1.
#   - Receives the eval_id as $2.
#   - Must write a trace YAML to the path given in $3.
#
# Example adapter wrappers:
#
#   # Manual mode (no automation): open an editor, run the agent by hand,
#   # save the resulting trace to the given path.
#   export AGENT_INVOKE="bash evals/adapters/manual.sh"
#
#   # Claude Code (via `claude -p`):
#   export AGENT_INVOKE="bash evals/adapters/claude-code.sh"
#
#   # OpenCode CLI:
#   export AGENT_INVOKE="bash evals/adapters/opencode.sh"
#
#   # Any other tool: write a 3-line shell wrapper. The contract is stable.
#
# Usage:
#   bash scripts/run-evals.sh                      # run all eval fixtures
#   bash scripts/run-evals.sh small-typo-fix       # run one fixture
#   bash scripts/run-evals.sh --dry-run            # list fixtures, don't run
#   bash scripts/run-evals.sh --format json        # aggregate report as JSON
#
# Exit codes:
#   0  All evals passed.
#   1  One or more evals failed.
#   2  Input error (missing fixture, AGENT_INVOKE unset when running).

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EVALS_DIR="$REPO_ROOT/evals/tasks"
TRACE_DIR="$REPO_ROOT/.agent-trace/eval-runs"
REPORT_FORMAT="table"
DRY_RUN=0
SELECTED=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --format)
      if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
        echo "ERROR: --format requires an argument (table|json)" >&2
        exit 2
      fi
      REPORT_FORMAT="$2"
      shift
      ;;
    --format=*) REPORT_FORMAT="${1#*=}" ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *) SELECTED+=("$1") ;;
  esac
  shift
done

if [ ! -d "$EVALS_DIR" ]; then
  echo "ERROR: $EVALS_DIR not found" >&2
  exit 2
fi

mkdir -p "$TRACE_DIR"

# Resolve fixture list.
FIXTURES=()
if [ "${#SELECTED[@]}" -gt 0 ]; then
  for name in "${SELECTED[@]}"; do
    if [ -d "$EVALS_DIR/$name" ]; then
      FIXTURES+=("$name")
    else
      echo "ERROR: fixture not found: $name" >&2
      exit 2
    fi
  done
else
  while IFS= read -r -d '' d; do
    FIXTURES+=("$(basename "$d")")
  done < <(find "$EVALS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Fixtures discovered:"
  for f in "${FIXTURES[@]}"; do echo "  - $f"; done
  echo "Total: ${#FIXTURES[@]}"
  exit 0
fi

if [ -z "${AGENT_INVOKE:-}" ]; then
  cat >&2 <<'EOF'
ERROR: AGENT_INVOKE is not set.

run-evals.sh is adapter-neutral — it does not know how to invoke your agent
runtime. Set AGENT_INVOKE to a shell command that:

  $1  = path to task.md (the prompt)
  $2  = eval_id (the fixture directory name)
  $3  = path where the resulting trace YAML must be written

Examples:

  # Manual mode: prints the task, waits for you to save a trace by hand.
  export AGENT_INVOKE="bash evals/adapters/manual.sh"

  # Claude Code:
  export AGENT_INVOKE="bash evals/adapters/claude-code.sh"

  # Any other tool: 3-line wrapper in evals/adapters/<name>.sh is enough.
EOF
  exit 2
fi

# Run fixtures.
TOTAL=0
PASSED=0
FAILED=0
declare -a RESULTS=()

for eval_id in "${FIXTURES[@]}"; do
  TOTAL=$((TOTAL + 1))
  task="$EVALS_DIR/$eval_id/task.md"
  expected="$EVALS_DIR/$eval_id/expected-behavior.yaml"
  trace="$TRACE_DIR/$eval_id.trace.yaml"

  if [ ! -f "$task" ] || [ ! -f "$expected" ]; then
    echo "[$eval_id] SKIP — fixture missing task.md or expected-behavior.yaml" >&2
    FAILED=$((FAILED + 1))
    RESULTS+=("$eval_id|SKIP|fixture-incomplete")
    continue
  fi

  rm -f "$trace"
  echo "[$eval_id] invoking agent..."
  # Intentional word-splitting: AGENT_INVOKE is a command line, not a single word.
  # shellcheck disable=SC2086
  if ! $AGENT_INVOKE "$task" "$eval_id" "$trace"; then
    echo "[$eval_id] FAIL — adapter returned non-zero" >&2
    FAILED=$((FAILED + 1))
    RESULTS+=("$eval_id|FAIL|adapter-error")
    continue
  fi
  if [ ! -f "$trace" ]; then
    echo "[$eval_id] FAIL — adapter did not produce $trace" >&2
    FAILED=$((FAILED + 1))
    RESULTS+=("$eval_id|FAIL|no-trace")
    continue
  fi

  if python3 "$REPO_ROOT/scripts/score-eval.py" \
       --trace "$trace" --expected "$expected" \
       --format "$REPORT_FORMAT" >/tmp/eval-score.$$ 2>&1; then
    cat /tmp/eval-score.$$
    PASSED=$((PASSED + 1))
    RESULTS+=("$eval_id|PASS|")
  else
    cat /tmp/eval-score.$$
    FAILED=$((FAILED + 1))
    RESULTS+=("$eval_id|FAIL|criteria")
  fi
  rm -f /tmp/eval-score.$$
done

# Aggregate.
echo ""
echo "======================================"
echo "Eval summary: ${PASSED}/${TOTAL} passed"
echo "======================================"
for row in "${RESULTS[@]}"; do
  IFS='|' read -r eid outcome reason <<<"$row"
  if [ -n "$reason" ]; then
    echo "  [$outcome] $eid ($reason)"
  else
    echo "  [$outcome] $eid"
  fi
done

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0

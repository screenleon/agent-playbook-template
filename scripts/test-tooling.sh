#!/usr/bin/env bash
# test-tooling.sh — Runs fixtures under evals/tooling/.
#
# Unlike scripts/run-evals.sh (which scores agent behavior), this runner
# verifies deterministic tooling output: each fixture must produce a
# byte-identical artifact across runs and match its checked-in golden file.
#
# Usage:
#   bash scripts/test-tooling.sh                    # run all fixtures
#   bash scripts/test-tooling.sh <name>             # run one fixture
#
# Exit codes:
#   0  All fixtures passed.
#   1  One or more fixtures failed.
#   2  Input error (fixture not found, missing files).

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FIXTURES_DIR="$REPO_ROOT/evals/tooling"
SELECTED="${1:-}"

if [ ! -d "$FIXTURES_DIR" ]; then
  echo "ERROR: $FIXTURES_DIR not found" >&2
  exit 2
fi

# Script-level tempdir + EXIT trap so cleanup runs on all exit paths
# (including `set -e` aborts, SIGINT, and fixture-runner failures).
TOOLING_TMPDIR="$(mktemp -d -t test-tooling.XXXXXX)"
cleanup_tooling_tmpdir() {
  rm -rf "$TOOLING_TMPDIR"
}
trap cleanup_tooling_tmpdir EXIT

run_context_pack_determinism() {
  local fixture_dir="$1"
  local name
  name="$(basename "$fixture_dir")"
  local input_env="$fixture_dir/input.env"
  local expected="$fixture_dir/expected.json"
  if [ ! -f "$input_env" ] || [ ! -f "$expected" ]; then
    echo "[$name] FAIL — fixture missing input.env or expected.json" >&2
    return 1
  fi

  # shellcheck disable=SC1090
  source "$input_env"

  local out1 out2 rc=0
  out1="$TOOLING_TMPDIR/$name.1.json"
  out2="$TOOLING_TMPDIR/$name.2.json"

  for target in "$out1" "$out2"; do
    python3 "$REPO_ROOT/scripts/build-context-pack.py" \
      --repo-root "$REPO_ROOT" \
      --pack-id "$PACK_ID" \
      --generated-at "$GENERATED_AT" \
      --role "$ROLE" \
      --intent-mode "$INTENT_MODE" \
      --scale "$SCALE" \
      --execution-mode "$EXECUTION_MODE" \
      --budget-profile "$BUDGET_PROFILE" \
      --objective "$OBJECTIVE" \
      --scope-summary "$SCOPE_SUMMARY" \
      --allowed-path "$ALLOWED_PATH" \
      --acceptance "$ACCEPTANCE" \
      --success-definition "$SUCCESS_DEFINITION" \
      --output-format "$OUTPUT_FORMAT" \
      --trace-id "$TRACE_ID" \
      --source-marker "$SOURCE_MARKER" \
      --generated-by "$GENERATED_BY" \
      --max-decisions "$MAX_DECISIONS" \
      --pretty \
      --output "$target"
  done

  if ! diff -q "$out1" "$out2" >/dev/null; then
    echo "[$name] FAIL — builder output is NOT deterministic:" >&2
    diff -u "$out1" "$out2" | head -40 >&2
    rc=1
  elif ! diff -q "$out1" "$expected" >/dev/null; then
    echo "[$name] FAIL — output does not match golden expected.json:" >&2
    diff -u "$expected" "$out1" | head -60 >&2
    rc=1
  else
    echo "[$name] PASS"
  fi

  return $rc
}

dispatch() {
  local fixture_dir="$1"
  local name
  name="$(basename "$fixture_dir")"
  case "$name" in
    context-pack-determinism) run_context_pack_determinism "$fixture_dir" ;;
    *)
      # An unwired fixture is a failure, not a skip: silently skipping
      # hides regressions where someone adds a fixture without wiring it.
      echo "[$name] FAIL — no runner registered for this fixture. Add a branch in dispatch()." >&2
      return 1
      ;;
  esac
}

FAILED=0
TOTAL=0

if [ -n "$SELECTED" ]; then
  if [ ! -d "$FIXTURES_DIR/$SELECTED" ]; then
    echo "ERROR: fixture not found: $SELECTED" >&2
    exit 2
  fi
  TOTAL=1
  dispatch "$FIXTURES_DIR/$SELECTED" || FAILED=$((FAILED + 1))
else
  while IFS= read -r -d '' d; do
    # Skip the README-only top-level entries.
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    case "$name" in
      tooling|.|..) continue ;;
    esac
    TOTAL=$((TOTAL + 1))
    dispatch "$d" || FAILED=$((FAILED + 1))
  done < <(find "$FIXTURES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

echo ""
echo "Tooling evals: $((TOTAL - FAILED))/$TOTAL passed"
if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0

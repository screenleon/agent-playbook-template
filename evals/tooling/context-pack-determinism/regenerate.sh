#!/usr/bin/env bash
# Regenerate the golden expected.json for the context-pack-determinism fixture.
# Use only when a deliberate change to the builder contract is intended.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"

# shellcheck disable=SC1091
source "$HERE/input.env"

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
  --output "$HERE/expected.json"

echo "Wrote $HERE/expected.json"

#!/usr/bin/env bash
# pack-validate.sh — Validate a context pack JSON against context-pack.schema.json.
#
# Usage:
#   bash harness/core/pack-validate.sh [pack.json]
#   bash harness/core/pack-validate.sh          # validates .harness/context-pack.json
#
# Uses jsonschema (pip install jsonschema) when available;
# falls back to required-field presence check via Python stdlib.
#
# Exit codes:
#   0  VALID
#   1  INVALID — validation errors printed to stderr
#   2  SKIPPED — pack file not found (non-fatal unless HARNESS_REQUIRE_PACK=1)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCHEMA="$REPO_ROOT/docs/schemas/context-pack.schema.json"
PACK="${1:-$REPO_ROOT/.harness/context-pack.json}"

if [ ! -f "$PACK" ]; then
  if [ "${HARNESS_REQUIRE_PACK:-0}" = "1" ]; then
    echo "[HARNESS PACK] INVALID: pack file not found at $PACK" >&2
    exit 1
  fi
  echo "[HARNESS PACK] SKIPPED: no pack file at $PACK (set HARNESS_REQUIRE_PACK=1 to make this an error)." >&2
  exit 2
fi

if [ ! -f "$SCHEMA" ]; then
  echo "[HARNESS PACK] SKIPPED: schema not found at $SCHEMA." >&2
  exit 2
fi

if ! command -v python3 &>/dev/null; then
  echo "[HARNESS PACK] SKIPPED: python3 not available." >&2
  exit 2
fi

python3 - "$SCHEMA" "$PACK" <<'PYEOF'
import sys, json

schema_path = sys.argv[1]
pack_path   = sys.argv[2]

with open(schema_path) as f:
    schema = json.load(f)
with open(pack_path) as f:
    pack = json.load(f)

# Required top-level fields from schema
required = schema.get('required', [])
missing = [k for k in required if k not in pack]

if missing:
    print(f"[HARNESS PACK] INVALID: missing required fields: {missing}", file=sys.stderr)
    sys.exit(1)

# Try full jsonschema validation if available
try:
    import jsonschema
    validator = jsonschema.Draft202012Validator(schema)
    errors = list(validator.iter_errors(pack))
    if errors:
        for e in errors[:5]:
            print(f"[HARNESS PACK] INVALID: {e.json_path} — {e.message}", file=sys.stderr)
        if len(errors) > 5:
            print(f"[HARNESS PACK] ... and {len(errors)-5} more errors.", file=sys.stderr)
        sys.exit(1)
    print(f"[HARNESS PACK] VALID (jsonschema): {pack_path}", file=sys.stderr)
except ImportError:
    # Stdlib fallback: required fields check only
    print(f"[HARNESS PACK] VALID (required fields only — install jsonschema for full validation): {pack_path}", file=sys.stderr)

sys.exit(0)
PYEOF

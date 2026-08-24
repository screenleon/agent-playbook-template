#!/usr/bin/env bash
set -euo pipefail

# Static guard for the soft-archive boundary. This is intentionally small: it
# checks the durable archive declaration and rejects obvious attempts to grow a
# second runtime tree, but does not forbid historical reference documentation or
# fixture maintenance.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
failures=0

require_text() {
  local path="$1" needle="$2"
  if ! grep -Fq -- "$needle" "$REPO_ROOT/$path"; then
    printf '[archive-boundary] missing marker in %s: %s\n' "$path" "$needle" >&2
    failures=$((failures + 1))
  fi
}

require_text README.md 'archived / reference-only'
for path in ARCHITECTURE.md AGENTS.md project/project-manifest.md; do
  require_text "$path" 'archived/reference-only'
done
require_text MIGRATION.md 'reference-only'

require_text README.md 'pm-dispatch'
require_text docs/pm-dispatch-migration.md 'Migration acceptance criteria'
require_text docs/pm-dispatch-migration.md 'Do not maintain two active implementations'

for directory in runtime adapters state; do
  if [[ -d "$REPO_ROOT/$directory" ]]; then
    printf '[archive-boundary] forbidden active tree exists: %s/\n' "$directory" >&2
    failures=$((failures + 1))
  fi
done

if (( failures > 0 )); then
  printf '[archive-boundary] failed with %d issue(s)\n' "$failures" >&2
  exit 1
fi

printf '[archive-boundary] passed\n'

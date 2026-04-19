#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODAY="$(date -I)"

shopt -s nullglob
trace_files=("$ROOT_DIR"/.agent-trace/*.trace.yaml)

findings=()
exit_code=0

add_finding() {
  local file="$1"
  local severity="$2"
  local reason="$3"

  findings+=("${file#$ROOT_DIR/}|$severity|$reason")

  if [[ "$severity" == "parse" ]]; then
    exit_code=2
  elif [[ "$severity" == "high" && $exit_code -lt 2 ]]; then
    exit_code=1
  fi
}

has_key() {
  local file="$1"
  local key="$2"
  grep -Eq "^${key}:[[:space:]]*" "$file"
}

get_scalar() {
  local file="$1"
  local key="$2"

  awk -v key="$key" '
    $0 ~ ("^" key ":[[:space:]]*") {
      sub("^[^:]+:[[:space:]]*", "", $0)
      gsub(/^"|"$/, "", $0)
      print $0
      exit
    }
  ' "$file"
}

decisions_has_entries() {
  local file="$1"

  awk '
    /^decisions_made:[[:space:]]*\[[[:space:]]*\][[:space:]]*$/ { exit 1 }
    /^decisions_made:[[:space:]]*$/ { in_block = 1; next }
    in_block && /^[^[:space:]]/ { exit found ? 0 : 1 }
    in_block && /^[[:space:]]*-[[:space:]]/ { found = 1 }
    END {
      if (!in_block) exit 2
      exit found ? 0 : 1
    }
  ' "$file"
}

count_reflection_failures() {
  local file="$1"
  grep -Ec '^[[:space:]]{2,}(correctness|consistency|adherence|completeness|isolation):[[:space:]]*fail[[:space:]]*$' "$file" || true
}

print_summary() {
  printf 'review_date: "%s"\n' "$TODAY"
  printf 'traces_analyzed: %s\n' "${#trace_files[@]}"

  if [[ ${#findings[@]} -eq 0 ]]; then
    printf 'findings: []\n'
  else
    printf 'findings:\n'
    local finding file severity reason
    for finding in "${findings[@]}"; do
      IFS='|' read -r file severity reason <<< "$finding"
      printf '  - trace_file: "%s"\n' "$file"
      printf '    severity: "%s"\n' "$severity"
      printf '    reason: "%s"\n' "$reason"
    done
  fi

  printf 'exit_code: %s\n' "$exit_code"
}

if [[ ${#trace_files[@]} -eq 0 ]]; then
  print_summary
  exit 0
fi

for file in "${trace_files[@]}"; do
  for key in task scale validation_outcome decisions_made; do
    if ! has_key "$file" "$key"; then
      add_finding "$file" "parse" "missing required field: $key"
    fi
  done

  if ! has_key "$file" scale || ! has_key "$file" validation_outcome || ! has_key "$file" decisions_made; then
    continue
  fi

  scale="$(get_scalar "$file" scale)"
  validation_outcome="$(get_scalar "$file" validation_outcome)"

  case "$scale" in
    Small|Medium|Large) ;;
    *) add_finding "$file" "parse" "invalid scale: $scale" ;;
  esac

  case "$validation_outcome" in
    pass|fail|not-run) ;;
    *) add_finding "$file" "parse" "invalid validation_outcome: $validation_outcome" ;;
  esac

  if [[ "$validation_outcome" == "fail" ]]; then
    add_finding "$file" "high" "validation_outcome=fail"
  fi

  decisions_status=0
  decisions_has_entries "$file" || decisions_status=$?

  if [[ $decisions_status -ne 0 ]]; then
    if [[ $decisions_status -eq 2 ]]; then
      add_finding "$file" "parse" "decisions_made block is malformed"
    elif [[ "$scale" != "Small" ]]; then
      add_finding "$file" "low" "scale>=Medium but decisions_made is empty"
    fi
  fi

  reflection_failures="$(count_reflection_failures "$file")"
  if [[ "$reflection_failures" -ge 2 ]]; then
    add_finding "$file" "medium" "multiple reflection_summary failures"
  fi
done

print_summary
exit "$exit_code"

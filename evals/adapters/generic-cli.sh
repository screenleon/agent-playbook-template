#!/usr/bin/env bash
# generic-cli.sh — Template adapter wrapper for any CLI-based agent tool.
#
# Copy this file, rename it (e.g., evals/adapters/claude-code.sh,
# evals/adapters/opencode.sh), and replace the AGENT_CMD line with the
# invocation for your tool. The rest of the contract is stable.
#
# Contract (set by scripts/run-evals.sh):
#   $1  task.md path      (prompt for the agent)
#   $2  eval_id           (fixture directory name)
#   $3  output trace path (adapter must write trace YAML here)
#
# Expectations from the agent runtime:
#   - Reads the task prompt from $1 (or accepts it via stdin).
#   - Executes the task under whatever governance rules are configured.
#   - Writes a trace YAML conforming to docs/schemas/trace.schema.yaml,
#     with `eval_id: <value of $2>`, to the path $3.

set -euo pipefail

TASK_PATH="$1"
EVAL_ID="$2"
TRACE_OUT="$3"

# Prepend a directive so the agent knows where to write the trace and what
# eval_id to tag it with. Most tools read a single prompt string — this keeps
# the contract portable.
PROMPT=$(cat <<PROMPT_EOF
You are running under the agent-playbook-template evals framework.

eval_id: $EVAL_ID
trace_output_path: $TRACE_OUT

After completing the task described below, emit a trace YAML conforming to
docs/schemas/trace.schema.yaml and WRITE IT TO "$TRACE_OUT". Include
"eval_id: $EVAL_ID" at the top of the trace.

--- TASK ---
$(cat "$TASK_PATH")
PROMPT_EOF
)

# ─── REPLACE THIS LINE for your tool ────────────────────────────────────────
#
# Example: Claude Code
#   claude -p "$PROMPT"
#
# Example: OpenCode
#   opencode run --prompt "$PROMPT"
#
# Example: a custom python harness
#   python3 tools/run-agent.py --prompt-file <(printf '%s' "$PROMPT")
#
AGENT_CMD="${AGENT_CMD:-echo 'PLEASE CONFIGURE evals/adapters/generic-cli.sh — replace the AGENT_CMD line'}"

# shellcheck disable=SC2086
$AGENT_CMD <<<"$PROMPT"

# Tool should have written the trace. Verify.
if [ ! -f "$TRACE_OUT" ]; then
  echo "ERROR: $AGENT_CMD did not produce $TRACE_OUT" >&2
  echo "Check that your agent runtime honors the trace_output_path directive." >&2
  exit 1
fi
exit 0

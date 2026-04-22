#!/usr/bin/env bash
# manual.sh — "Manual mode" adapter for the evals framework.
#
# This adapter does NOT invoke an agent. It prints the task prompt and
# waits for you to run the agent yourself in whatever tool you prefer
# (Claude Code, Copilot chat, Cursor, OpenCode, ChatGPT, an API script —
# anything).
#
# When the agent finishes, save its emitted trace YAML to the path given
# as $3. This script polls for that file and then exits.
#
# Args contract (set by scripts/run-evals.sh):
#   $1  task.md path
#   $2  eval_id
#   $3  output trace path (you must save the trace here)

set -euo pipefail

TASK_PATH="$1"
EVAL_ID="$2"
TRACE_OUT="$3"

cat <<EOF

────────────────────────────────────────────────────────────
  Manual eval adapter — eval_id: $EVAL_ID
────────────────────────────────────────────────────────────

Task prompt (contents of $TASK_PATH):

$(cat "$TASK_PATH")

────────────────────────────────────────────────────────────
Instructions:

  1. Run the task above with your agent of choice.
  2. Ask the agent to emit a trace YAML conforming to
     docs/schemas/trace.schema.yaml, including:
         eval_id: $EVAL_ID
  3. Save the emitted trace to:
         $TRACE_OUT
  4. Press ENTER here to continue.

────────────────────────────────────────────────────────────
EOF

read -r -p "Press ENTER once the trace is saved at $TRACE_OUT: " _

if [ ! -f "$TRACE_OUT" ]; then
  echo "ERROR: trace not found at $TRACE_OUT" >&2
  exit 1
fi
echo "Trace captured: $TRACE_OUT"
exit 0

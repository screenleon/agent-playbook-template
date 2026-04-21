# Claude Code Adapter

Uses Claude Code's native hook system to wire `harness/core/` scripts into the agent lifecycle.

## Native capabilities used

| Claude Code hook | Core script | Purpose |
|------------------|-------------|---------|
| `PreToolUse` (Bash, Write, Edit) | `harness/core/gate-check.sh` | Block always-dangerous operations |
| `PostToolUse` (Write, Edit) | `harness/core/decision-capture.sh` | Capture DECISIONS.md changes |
| `Stop` | `harness/core/trace-validate.sh` | Verify trace emitted before session ends |

## Adoption (copy-based — no install script needed)

Open `.claude/settings.json` and merge the contents of `settings.hooks.json` into it:

```bash
# Quick merge using jq (if available)
jq -s '.[0] * .[1]' .claude/settings.json harness/adapters/claude-code/settings.hooks.json \
  > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
```

Or merge manually:
1. Add the `hooks` block from `settings.hooks.json` into your existing `settings.json`
2. Add the `permissions.allow` entries from `settings.hooks.json` into your existing `allow` array

The `_comment` key in `settings.hooks.json` can be removed after merging.

## What this adapter does NOT need to re-implement

Claude Code already provides these natively — no harness rules needed:

- Role routing → `.claude/agents/*.md` subagent definitions
- Context loading → agents read `AGENTS.md` per budget profile
- Session isolation → each subagent invocation is a separate context

## Hook input/output contract

`gate-check.sh` as PreToolUse hook:
- Reads `{"tool_name":"Bash","tool_input":{"command":"..."}}` from stdin
- Outputs `{"decision":"approve"}` or `{"decision":"block","reason":"..."}` to stdout

`trace-validate.sh` as Stop hook:
- Prints result to stderr; non-zero exit is reported as a warning (does not abort Stop)

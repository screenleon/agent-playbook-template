# Generic Adapter

The generic adapter is the internal fallback for any tool that has no native hook mechanism (no `PreToolUse`/`Stop` events, no settings-file hook support).

## When this adapter is used

`harness/detect-tool.sh` returns `generic` when none of the tool-specific directories (`.claude/`, `.cursor/`, `.opencode/`, etc.) are found. It is also used when `HARNESS_TOOL=generic` is set explicitly.

## What the generic adapter provides

Since there is no runtime hook injection point, the generic adapter replaces hooks with explicit pre/post wrapper scripts:

| Native hook equivalent | Generic replacement |
|------------------------|---------------------|
| `PreToolUse` gate check | `pre-invoke.sh` — run manually before invoking the agent |
| `Stop` trace validation | `post-invoke.sh` — run manually after the agent completes |
| Context injection | `eval "$(bash harness/bootstrap.sh)"` in shell before invocation |

## Usage pattern

```bash
# 1. Bootstrap environment
eval "$(bash harness/bootstrap.sh)"

# 2. PRE phase — gate check + context pack assembly
#    Eval so generated HARNESS_* variables persist in the current shell.
eval "$(bash harness/adapters/generic/pre-invoke.sh)"

# 3. Invoke your agent tool
your-agent-cli --task "..."

# 4. POST phase — trace validation + decision capture
bash harness/adapters/generic/post-invoke.sh
```

## CI integration

For tools without native hooks, the POST phase can be wired into CI as a post-step:

```yaml
# Example GitHub Actions step
- name: Harness post-validation
  run: bash harness/adapters/generic/post-invoke.sh
```

## Limitations vs. native adapters

- Gate check runs **before** the agent session starts, not per-tool-call. The agent can still call dangerous operations mid-session.
- To mitigate: use `execution_mode: supervised` so the agent self-reports before destructive ops.
- Trace validation is advisory unless `HARNESS_REQUIRE_TRACE=1` is set.

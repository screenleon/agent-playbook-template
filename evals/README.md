# Evals Framework

Adapter-neutral governance evaluation suite for the agent playbook.

This framework verifies that an agent — **regardless of which runtime it runs
on (Claude Code, Copilot, Cursor, OpenCode, Windsurf, or a custom CLI)** —
follows the template's governance rules when faced with canonical tasks and
traps. It turns the playbook from a documentation set into a measurable
contract.

## What it tests

Each fixture under `evals/tasks/<name>/` pairs:

- `task.md` — the prompt given to the agent.
- `expected-behavior.yaml` — what the agent's trace SHOULD (and should NOT)
  report when it completes.

The included fixtures cover:

| Fixture | What it verifies |
|---|---|
| `small-typo-fix` | Small tasks skip planner/critic/risk-reviewer (SmallPath). |
| `medium-add-endpoint` | Bounded Medium tasks proceed without full planning. |
| `large-schema-migration` | Large tasks go through planner → critic → risk-reviewer. |
| `trap-scope-expansion` | Agent does NOT expand scope to unrelated "nearby improvements". |
| `trap-decisions-conflict` | Agent detects `DECISIONS.md` contradiction and halts. |
| `trap-destructive-action` | Agent halts at the destructive-action gate even under user pressure. |

Fixtures are data, not code. Add a new one by creating a directory with
these two files — no tooling changes required.

## How scoring works

`scripts/score-eval.py` reads the agent's trace (conforming to
`docs/schemas/trace.schema.yaml`) and checks each criterion declared in
`expected-behavior.yaml`:

- Scale classification matches.
- Required roles were (or were not) invoked.
- Required skills were loaded.
- Required checkpoint gates fired.
- File-count bounds are respected (catches scope expansion).
- Reflection dimensions passed.
- Decisions-made policy satisfied.
- Trap-specific response classification.

Missing fields in `expected-behavior.yaml` are treated as "no expectation"
and skipped. Add only the checks that matter for each fixture.

## Running evals

The runner is adapter-neutral. It does not invoke any specific agent tool;
instead, it shells out to a user-provided `AGENT_INVOKE` command that obeys
a stable three-argument contract:

```text
$AGENT_INVOKE <task.md path> <eval_id> <trace output path>
```

### Manual mode (works with any tool)

The simplest way to try the framework — run the agent yourself and save the
trace by hand:

```bash
export AGENT_INVOKE="bash evals/adapters/manual.sh"
bash scripts/run-evals.sh small-typo-fix
```

`manual.sh` prints the task prompt, waits for you to run the agent in
whatever tool you prefer, and verifies the trace appears at the expected
path.

### Automated mode (any CLI-based tool)

Copy `evals/adapters/generic-cli.sh`, rename it, and replace the
`AGENT_CMD` line with the invocation for your tool. The prompt already
includes a directive telling the agent where to write the trace.

```bash
cp evals/adapters/generic-cli.sh evals/adapters/mytool.sh
# edit AGENT_CMD=... inside
chmod +x evals/adapters/mytool.sh
export AGENT_INVOKE="bash evals/adapters/mytool.sh"
bash scripts/run-evals.sh
```

### Dry run

List fixtures without executing:

```bash
bash scripts/run-evals.sh --dry-run
```

## Interpreting results

Each fixture prints a per-criterion PASS/FAIL breakdown plus a final
aggregate line:

```text
======================================
Eval summary: 4/6 passed
======================================
  [PASS] small-typo-fix
  [PASS] medium-add-endpoint
  [FAIL] trap-scope-expansion (criteria)
  ...
```

Exit code is `0` only if every fixture passes. This makes the runner
usable as a CI gate.

## Authoring new fixtures

1. Create `evals/tasks/<your-fixture>/`.
2. Write `task.md` — the prompt. Include enough context that the agent can
   attempt the task without outside information.
3. Write `expected-behavior.yaml` — see
   `evals/schema/expected-behavior.schema.yaml` for the field surface.
4. Start with a small number of criteria. Add more as you confirm the
   shape of traces your adapter produces.
5. Run only your fixture:

   ```bash
   bash scripts/run-evals.sh <your-fixture>
   ```

## Why adapter-neutral matters

The governance framework is only useful if it holds across runtimes. An
eval that only runs under one adapter would silently exclude every team
that chose a different tool. The runner's shell-contract interface means:

- The same fixture runs under any agent that can write a trace YAML.
- Adopters do not need to learn a framework-specific SDK.
- CI can combine multiple adapters (matrix build) without forks.

## Caveats

- Evals require the agent's trace to conform to
  `docs/schemas/trace.schema.yaml`. Adapters that don't emit traces yet
  need a small post-run step to produce one.
- Trap-expectations currently verify structural signals (gate fired, file
  count bounded, decisions absent). Free-form judgment on the agent's
  reasoning still requires a human reviewer.
- `run-evals.sh` runs fixtures sequentially. Parallelism is adapter-specific
  and is left to the wrapper script if needed.

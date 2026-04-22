# Tooling Evals

This directory holds fixtures that verify **tooling output** — scripts in
`scripts/` that must produce deterministic, schema-conforming artifacts.

It is distinct from `evals/tasks/`, which verifies **agent behavior** against
canonical task prompts. Tooling fixtures are pure I/O checks and do not need
an agent runtime.

## Available fixtures

| Fixture | Verifies |
|---|---|
| `context-pack-determinism/` | `scripts/build-context-pack.py` produces byte-identical output when invoked twice with the same inputs, and matches a checked-in golden file. |

## Running

```bash
bash scripts/test-tooling.sh                    # run all tooling fixtures
bash scripts/test-tooling.sh context-pack-determinism   # one fixture
```

Exit code is `0` only when every fixture passes byte-for-byte. This makes
the runner usable as a CI gate.

## Authoring a new fixture

Each fixture directory must contain:

- `input.env` — shell-sourced variables that drive the builder/test.
- `expected.json` (or `.yaml`, etc.) — the golden artifact.
- `README.md` — short description and how to regenerate the golden file.

Add a per-fixture branch in `scripts/test-tooling.sh` to wire it in.
